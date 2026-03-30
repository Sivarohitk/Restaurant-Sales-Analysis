"""Reproducible analysis pipeline for the Restaurant Sales Intelligence project."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import pandas as pd

TIME_OF_SALE_ORDER = ["Morning", "Afternoon", "Evening", "Night", "Midnight"]
PAYMENT_TYPE_ORDER = ["Cash", "Online", "Unknown"]
PRIMARY_COLOR = "#0b6e4f"
SECONDARY_COLOR = "#c75c00"
ACCENT_COLOR = "#4c7cbf"


@dataclass(frozen=True)
class ProjectPaths:
    """Filesystem locations used by the project."""

    root: Path
    raw_data: Path
    processed_dir: Path
    outputs_tables: Path
    outputs_charts: Path


def get_project_paths() -> ProjectPaths:
    """Resolve key project paths relative to this file."""

    root = Path(__file__).resolve().parents[1]
    return ProjectPaths(
        root=root,
        raw_data=root / "data" / "raw" / "restaurant_sales.csv",
        processed_dir=root / "data" / "processed",
        outputs_tables=root / "outputs" / "tables",
        outputs_charts=root / "outputs" / "charts",
    )


def clean_column_names(df: pd.DataFrame) -> pd.DataFrame:
    """Standardize columns to lowercase snake_case."""

    cleaned = df.copy()
    cleaned.columns = (
        cleaned.columns.str.strip()
        .str.lower()
        .str.replace(r"[^0-9a-z]+", "_", regex=True)
        .str.strip("_")
    )
    return cleaned


def parse_mixed_dates(date_series: pd.Series) -> tuple[pd.Series, pd.Series]:
    """Parse the two known source date formats safely."""

    source = date_series.astype("string").str.strip()
    parsed = pd.Series(pd.NaT, index=source.index, dtype="datetime64[ns]")
    date_format_source = pd.Series("unknown", index=source.index, dtype="string")

    dash_mask = source.str.contains("-", regex=False, na=False)
    slash_mask = source.str.contains("/", regex=False, na=False)

    parsed.loc[dash_mask] = pd.to_datetime(
        source.loc[dash_mask], format="%d-%m-%Y", errors="coerce"
    )
    parsed.loc[slash_mask] = pd.to_datetime(
        source.loc[slash_mask], format="%m/%d/%Y", errors="coerce"
    )

    date_format_source.loc[dash_mask] = "dd-mm-yyyy"
    date_format_source.loc[slash_mask] = "mm/dd/yyyy"

    return parsed, date_format_source


def load_raw_data(csv_path: Path) -> pd.DataFrame:
    """Load the raw CSV and standardize its headers."""

    return clean_column_names(pd.read_csv(csv_path))


def prepare_clean_dataset(raw_df: pd.DataFrame) -> pd.DataFrame:
    """Clean and enrich the raw restaurant sales data."""

    cleaned = raw_df.copy()
    cleaned["date_raw"] = cleaned["date"].astype("string").str.strip()
    cleaned["order_date"], cleaned["date_format_source"] = parse_mixed_dates(
        cleaned["date_raw"]
    )
    cleaned["transaction_type"] = (
        cleaned["transaction_type"].astype("string").str.strip().replace({"<NA>": pd.NA})
    )
    cleaned["missing_transaction_type_flag"] = cleaned["transaction_type"].isna()
    cleaned["transaction_type"] = cleaned["transaction_type"].fillna("Unknown")

    for column in ["item_name", "item_type", "received_by", "time_of_sale"]:
        cleaned[column] = cleaned[column].astype("string").str.strip()

    cleaned["expected_transaction_amount"] = cleaned["item_price"] * cleaned["quantity"]
    cleaned["transaction_amount_matches_expected"] = (
        cleaned["transaction_amount"] == cleaned["expected_transaction_amount"]
    )
    cleaned["parsed_date_missing_flag"] = cleaned["order_date"].isna()
    cleaned["received_by_is_ambiguous_flag"] = cleaned["received_by"].isin(["Mr.", "Mrs."])
    cleaned["duplicate_order_id_flag"] = cleaned["order_id"].duplicated(keep=False)
    cleaned["has_any_quality_flag"] = cleaned[
        [
            "missing_transaction_type_flag",
            "parsed_date_missing_flag",
            "duplicate_order_id_flag",
        ]
    ].any(axis=1) | (~cleaned["transaction_amount_matches_expected"])

    cleaned["order_year"] = cleaned["order_date"].dt.year
    cleaned["order_month"] = cleaned["order_date"].dt.to_period("M").astype("string")
    cleaned["order_month_start"] = cleaned["order_date"].dt.to_period("M").dt.to_timestamp()
    cleaned["order_month_name"] = cleaned["order_date"].dt.strftime("%b %Y")
    cleaned["order_day_name"] = cleaned["order_date"].dt.day_name()

    cleaned = cleaned.drop(columns=["date"])

    ordered_columns = [
        "order_id",
        "date_raw",
        "order_date",
        "date_format_source",
        "order_year",
        "order_month",
        "order_month_start",
        "order_month_name",
        "order_day_name",
        "item_name",
        "item_type",
        "item_price",
        "quantity",
        "transaction_amount",
        "expected_transaction_amount",
        "transaction_amount_matches_expected",
        "transaction_type",
        "missing_transaction_type_flag",
        "received_by",
        "received_by_is_ambiguous_flag",
        "time_of_sale",
        "parsed_date_missing_flag",
        "duplicate_order_id_flag",
        "has_any_quality_flag",
    ]
    return cleaned[ordered_columns]


def build_data_quality_summary(cleaned_df: pd.DataFrame) -> pd.DataFrame:
    """Create a concise, auditable summary of data quality checks."""

    dash_rows = int((cleaned_df["date_format_source"] == "dd-mm-yyyy").sum())
    slash_rows = int((cleaned_df["date_format_source"] == "mm/dd/yyyy").sum())
    ambiguous_received_by = sorted(cleaned_df["received_by"].dropna().unique().tolist())

    records = [
        {
            "issue_type": "mixed_date_formats",
            "affected_rows": len(cleaned_df),
            "status": "reviewed",
            "detail": (
                f"{dash_rows} rows used dd-mm-yyyy and {slash_rows} rows used mm/dd/yyyy; "
                "the pipeline parses both formats explicitly."
            ),
        },
        {
            "issue_type": "missing_transaction_type",
            "affected_rows": int(cleaned_df["missing_transaction_type_flag"].sum()),
            "status": "handled",
            "detail": "Missing payment values are retained as Unknown and flagged for transparency.",
        },
        {
            "issue_type": "transaction_amount_validation",
            "affected_rows": int((~cleaned_df["transaction_amount_matches_expected"]).sum()),
            "status": "validated",
            "detail": "Validated whether transaction_amount equals item_price multiplied by quantity.",
        },
        {
            "issue_type": "duplicate_order_id_check",
            "affected_rows": int(cleaned_df["duplicate_order_id_flag"].sum()),
            "status": "validated",
            "detail": "Checked whether order_id values repeat across the source file.",
        },
        {
            "issue_type": "received_by_field_limitation",
            "affected_rows": int(cleaned_df["received_by_is_ambiguous_flag"].sum()),
            "status": "documented",
            "detail": (
                "received_by contains only honorific labels "
                f"{ambiguous_received_by}; it is treated as a category label, not a true employee identifier."
            ),
        },
        {
            "issue_type": "unparsed_dates",
            "affected_rows": int(cleaned_df["parsed_date_missing_flag"].sum()),
            "status": "validated",
            "detail": "Any rows listed here could not be parsed into a valid calendar date.",
        },
    ]

    return pd.DataFrame(records)


def build_summary_tables(cleaned_df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    """Create portfolio-ready summary tables for analysis and export."""

    total_revenue = float(cleaned_df["transaction_amount"].sum())
    total_orders = int(cleaned_df["order_id"].nunique())
    total_quantity = int(cleaned_df["quantity"].sum())

    kpi_summary = pd.DataFrame(
        [
            {"metric": "total_revenue", "value": round(total_revenue, 2)},
            {"metric": "total_orders", "value": total_orders},
            {"metric": "total_quantity_sold", "value": total_quantity},
            {
                "metric": "average_order_value",
                "value": round(cleaned_df.groupby("order_id")["transaction_amount"].sum().mean(), 2),
            },
            {
                "metric": "average_quantity_per_order",
                "value": round(cleaned_df.groupby("order_id")["quantity"].sum().mean(), 2),
            },
            {
                "metric": "missing_payment_share_pct",
                "value": round(cleaned_df["missing_transaction_type_flag"].mean() * 100, 2),
            },
        ]
    )

    monthly_sales = (
        cleaned_df.groupby("order_month", dropna=False)
        .agg(
            orders=("order_id", "count"),
            quantity_sold=("quantity", "sum"),
            revenue=("transaction_amount", "sum"),
        )
        .reset_index()
        .sort_values("order_month")
    )
    monthly_sales["average_order_value"] = (
        monthly_sales["revenue"] / monthly_sales["orders"]
    ).round(2)

    revenue_by_item = (
        cleaned_df.groupby("item_name")
        .agg(
            orders=("order_id", "count"),
            quantity_sold=("quantity", "sum"),
            revenue=("transaction_amount", "sum"),
        )
        .reset_index()
        .sort_values("revenue", ascending=False)
    )
    revenue_by_item["revenue_share_pct"] = (
        revenue_by_item["revenue"] / total_revenue * 100
    ).round(2)
    revenue_by_item["average_order_value"] = (
        revenue_by_item["revenue"] / revenue_by_item["orders"]
    ).round(2)

    quantity_by_item = revenue_by_item.sort_values("quantity_sold", ascending=False).reset_index(
        drop=True
    )
    quantity_by_item["quantity_share_pct"] = (
        quantity_by_item["quantity_sold"] / total_quantity * 100
    ).round(2)

    sales_by_time_of_sale = (
        cleaned_df.groupby("time_of_sale")
        .agg(
            orders=("order_id", "count"),
            quantity_sold=("quantity", "sum"),
            revenue=("transaction_amount", "sum"),
        )
        .reindex(TIME_OF_SALE_ORDER)
        .dropna(how="all")
        .reset_index()
    )
    sales_by_time_of_sale["average_order_value"] = (
        sales_by_time_of_sale["revenue"] / sales_by_time_of_sale["orders"]
    ).round(2)
    sales_by_time_of_sale["revenue_share_pct"] = (
        sales_by_time_of_sale["revenue"] / total_revenue * 100
    ).round(2)

    sales_by_payment_type = (
        cleaned_df.groupby("transaction_type")
        .agg(
            orders=("order_id", "count"),
            quantity_sold=("quantity", "sum"),
            revenue=("transaction_amount", "sum"),
        )
        .reindex(PAYMENT_TYPE_ORDER)
        .dropna(how="all")
        .reset_index()
        .rename(columns={"transaction_type": "payment_type"})
    )
    sales_by_payment_type["order_share_pct"] = (
        sales_by_payment_type["orders"] / total_orders * 100
    ).round(2)
    sales_by_payment_type["average_order_value"] = (
        sales_by_payment_type["revenue"] / sales_by_payment_type["orders"]
    ).round(2)

    item_type_mix = (
        cleaned_df.groupby("item_type")
        .agg(
            orders=("order_id", "count"),
            quantity_sold=("quantity", "sum"),
            revenue=("transaction_amount", "sum"),
        )
        .reset_index()
        .sort_values("revenue", ascending=False)
    )
    item_type_mix["revenue_share_pct"] = (item_type_mix["revenue"] / total_revenue * 100).round(2)
    item_type_mix["quantity_share_pct"] = (
        item_type_mix["quantity_sold"] / total_quantity * 100
    ).round(2)

    item_type_time_of_sale = (
        cleaned_df.groupby(["item_type", "time_of_sale"])
        .agg(
            orders=("order_id", "count"),
            quantity_sold=("quantity", "sum"),
            revenue=("transaction_amount", "sum"),
        )
        .reset_index()
    )
    item_type_time_of_sale["average_order_value"] = (
        item_type_time_of_sale["revenue"] / item_type_time_of_sale["orders"]
    ).round(2)
    item_type_time_of_sale["time_of_sale"] = pd.Categorical(
        item_type_time_of_sale["time_of_sale"],
        categories=TIME_OF_SALE_ORDER,
        ordered=True,
    )
    item_type_time_of_sale = item_type_time_of_sale.sort_values(
        ["item_type", "time_of_sale"]
    ).reset_index(drop=True)

    return {
        "kpi_summary": kpi_summary,
        "monthly_sales_trend": monthly_sales,
        "revenue_by_item": revenue_by_item,
        "quantity_by_item": quantity_by_item,
        "sales_by_time_of_sale": sales_by_time_of_sale,
        "sales_by_payment_type": sales_by_payment_type,
        "item_type_mix": item_type_mix,
        "item_type_time_of_sale_performance": item_type_time_of_sale,
    }


def export_tables(summary_tables: dict[str, pd.DataFrame], destination: Path) -> None:
    """Save summary tables as CSV files."""

    destination.mkdir(parents=True, exist_ok=True)
    for table_name, table_df in summary_tables.items():
        table_df.to_csv(destination / f"{table_name}.csv", index=False)


def _save_bar_chart(
    data: pd.DataFrame,
    label_column: str,
    value_column: str,
    title: str,
    x_label: str,
    output_path: Path,
    color: str,
    horizontal: bool = False,
) -> None:
    """Shared helper for simple bar charts."""

    fig, ax = plt.subplots(figsize=(10, 6))
    if horizontal:
        ax.barh(data[label_column], data[value_column], color=color)
        ax.invert_yaxis()
        ax.set_xlabel(x_label)
    else:
        ax.bar(data[label_column], data[value_column], color=color)
        ax.set_ylabel(x_label)
        ax.tick_params(axis="x", rotation=20)

    ax.set_title(title, fontsize=14, weight="bold")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(output_path, dpi=180, bbox_inches="tight")
    plt.close(fig)


def create_charts(summary_tables: dict[str, pd.DataFrame], destination: Path) -> None:
    """Generate portfolio charts into the outputs directory."""

    destination.mkdir(parents=True, exist_ok=True)

    monthly = summary_tables["monthly_sales_trend"]
    fig, ax = plt.subplots(figsize=(11, 6))
    ax.plot(monthly["order_month"], monthly["revenue"], marker="o", linewidth=2.5, color=PRIMARY_COLOR)
    ax.set_title("Monthly Revenue Trend", fontsize=14, weight="bold")
    ax.set_xlabel("Month")
    ax.set_ylabel("Revenue")
    ax.tick_params(axis="x", rotation=45)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(destination / "monthly_revenue_trend.png", dpi=180, bbox_inches="tight")
    plt.close(fig)

    _save_bar_chart(
        data=summary_tables["revenue_by_item"],
        label_column="item_name",
        value_column="revenue",
        title="Revenue by Item",
        x_label="Revenue",
        output_path=destination / "revenue_by_item.png",
        color=PRIMARY_COLOR,
        horizontal=True,
    )

    _save_bar_chart(
        data=summary_tables["quantity_by_item"],
        label_column="item_name",
        value_column="quantity_sold",
        title="Quantity Sold by Item",
        x_label="Units Sold",
        output_path=destination / "quantity_sold_by_item.png",
        color=SECONDARY_COLOR,
        horizontal=True,
    )

    _save_bar_chart(
        data=summary_tables["sales_by_time_of_sale"],
        label_column="time_of_sale",
        value_column="revenue",
        title="Sales by Time of Sale",
        x_label="Revenue",
        output_path=destination / "sales_by_time_of_sale.png",
        color=ACCENT_COLOR,
    )

    _save_bar_chart(
        data=summary_tables["sales_by_payment_type"],
        label_column="payment_type",
        value_column="revenue",
        title="Sales by Payment Type",
        x_label="Revenue",
        output_path=destination / "sales_by_payment_type.png",
        color=SECONDARY_COLOR,
    )

    item_type_mix = summary_tables["item_type_mix"]
    fig, ax = plt.subplots(figsize=(8, 6))
    x_positions = range(len(item_type_mix))
    width = 0.36
    ax.bar(
        [value - width / 2 for value in x_positions],
        item_type_mix["revenue_share_pct"],
        width=width,
        color=PRIMARY_COLOR,
        label="Revenue Share %",
    )
    ax.bar(
        [value + width / 2 for value in x_positions],
        item_type_mix["quantity_share_pct"],
        width=width,
        color=SECONDARY_COLOR,
        label="Quantity Share %",
    )
    ax.set_title("Item Type Mix", fontsize=14, weight="bold")
    ax.set_xticks(list(x_positions))
    ax.set_xticklabels(item_type_mix["item_type"])
    ax.set_ylabel("Share (%)")
    ax.legend(frameon=False)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(destination / "item_type_mix.png", dpi=180, bbox_inches="tight")
    plt.close(fig)


def write_processed_outputs(cleaned_df: pd.DataFrame, quality_summary: pd.DataFrame, paths: ProjectPaths) -> None:
    """Persist processed datasets that support reproducibility."""

    paths.processed_dir.mkdir(parents=True, exist_ok=True)
    cleaned_df.to_csv(paths.processed_dir / "restaurant_sales_clean.csv", index=False)
    quality_summary.to_csv(paths.processed_dir / "data_quality_issues.csv", index=False)


def main() -> None:
    """Run the end-to-end project pipeline."""

    paths = get_project_paths()
    raw_df = load_raw_data(paths.raw_data)
    cleaned_df = prepare_clean_dataset(raw_df)
    quality_summary = build_data_quality_summary(cleaned_df)
    summary_tables = build_summary_tables(cleaned_df)

    write_processed_outputs(cleaned_df, quality_summary, paths)
    export_tables(summary_tables, paths.outputs_tables)
    create_charts(summary_tables, paths.outputs_charts)

    print(f"Processed {len(cleaned_df):,} rows from {paths.raw_data.name}.")
    print(f"Clean dataset written to: {paths.processed_dir}")
    print(f"Summary tables written to: {paths.outputs_tables}")
    print(f"Charts written to: {paths.outputs_charts}")


if __name__ == "__main__":
    main()
