import pandas as pd
import numpy as np
import streamlit as st
import matplotlib.pyplot as plt

# ========= 1. Load Data =========
@st.cache_data
def load_data():
    df = pd.read_csv("C:/Users/Myola/Desktop/Stats 6289 Python database mgmt/project/hotel_weather.csv")
    df["original_arrival_date"] = pd.to_datetime(df["original_arrival_date"], errors="coerce")
    return df

df = load_data()

st.title("Interactive Hotel Booking Explorer")
st.write("Powered by dataset: `hotel_weather` (bookings + customers + weather)")

# ========= 2. Sidebar Filters =========
st.sidebar.header("Filters")

# Hotel type filter
hotel_opts = sorted(df["hotel"].dropna().unique().tolist())
selected_hotels = st.sidebar.multiselect(
    "Hotel Type",
    options=hotel_opts,
    default=hotel_opts
)

# Location filter
loc_opts = sorted(df["location"].dropna().unique().tolist())
selected_locs = st.sidebar.multiselect(
    "Location",
    options=loc_opts,
    default=loc_opts
)

# Year filter
year_opts = sorted(df["arrival_date_year"].dropna().unique().tolist())
selected_years = st.sidebar.multiselect(
    "Arrival Year",
    options=year_opts,
    default=year_opts
)

# Filter the dataset
mask = (
    df["hotel"].isin(selected_hotels)
    & df["location"].isin(selected_locs)
    & df["arrival_date_year"].isin(selected_years)
)
f = df[mask].copy()

# Display summary stats
st.subheader("Summary for Filtered Dataset")
c1, c2, c3, c4 = st.columns(4)
with c1:
    st.metric("Booking Count", len(f))
with c2:
    cancel_rate = (f["is_canceled"] == 1).mean() * 100 if len(f) > 0 else 0
    st.metric("Cancellation Rate (%)", f"{cancel_rate:.2f}")
with c3:
    st.metric("Hotel Types", len(selected_hotels))
with c4:
    st.metric("Locations", len(selected_locs))

st.dataframe(f.head())
st.markdown("---")


# ========= 3. Categorical Variable Explorer =========
st.subheader("① Categorical Variable: Cancellation Rate + Weather Frequency View")

cat_cols = [
    "hotel", "location", "arrival_date_month", "meal", "country",
    "market_segment", "distribution_channel", "deposit_type",
    "customer_type", "reservation_status"
]

cat_var = st.selectbox("Choose a Categorical Variable:", cat_cols, index=2)

if f.empty:
    st.warning("Filtered dataset is empty — adjust filter selections.")
else:
    tmp = f.copy()
    tmp[cat_var] = tmp[cat_var].fillna("Unknown")
    tmp["weather"] = tmp["weather"].fillna("Unknown_weather")

    # ---- 3.1 Category vs Cancellation Rate (all bookings) ----
    grouped = (
        tmp.groupby(cat_var)
           .agg(
               total_bookings=("is_canceled", "size"),
               canceled_bookings=("is_canceled", lambda x: (x == 1).sum())
           )
           .reset_index()
    )
    grouped["cancel_rate"] = (grouped["canceled_bookings"] * 100.0 /
                              grouped["total_bookings"]).round(2)
    grouped = grouped.sort_values("cancel_rate", ascending=True)

    st.write("(a) Cancellation Rate by Category (all bookings)")
    st.dataframe(grouped)

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.barh(grouped[cat_var], grouped["cancel_rate"])
    ax.set_title(f"Cancellation Rate by {cat_var}")
    ax.set_xlabel("Cancellation Rate (%)")
    ax.set_ylabel(cat_var)
    ax.grid(axis="x", alpha=0.3)
    st.pyplot(fig)

    # ---- 3.2 Weather Frequency by Category: All bookings vs Canceled only ----
    st.write("### (b) Weather distribution within categories (Counts & Percentages)")

    # If the categorical variable has too many levels (e.g. country),
    # restrict to top 10 categories by frequency.
    if cat_var == "country":
        top_categories = (
            tmp[cat_var]
            .value_counts()
            .head(10)
            .index
            .tolist()
        )
        tmp = tmp[tmp[cat_var].isin(top_categories)].copy()

    # Determine top-8 weathers (based on all filtered data after category restriction)
    top_weathers = (
        tmp["weather"]
        .value_counts()
        .head(8)
        .index
        .tolist()
    )

    # ---------- ALL BOOKINGS ----------
    tmp_all = tmp[tmp["weather"].isin(top_weathers)].copy()

    weather_counts_all = (
        tmp_all.groupby([cat_var, "weather"])
        .size()
        .reset_index(name="count")
    )

    pivot_all = weather_counts_all.pivot(
        index=cat_var, columns="weather", values="count"
    ).fillna(0)

    # Create unified ordering (sorted by total count)
    category_order = pivot_all.sum(axis=1).sort_values(ascending=False).index.tolist()
    pivot_all = pivot_all.loc[category_order]

    # Percentage version (row-wise)
    pivot_all_pct = pivot_all.div(pivot_all.sum(axis=1), axis=0) * 100
    pivot_all_pct = pivot_all_pct.round(2)

    # ---------- CANCELED ONLY ----------
    tmp_cancel = tmp[(tmp["is_canceled"] == 1) & (tmp["weather"].isin(top_weathers))].copy()

    if tmp_cancel.empty:
        pivot_cancel = None
        pivot_cancel_pct = None
    else:
        weather_counts_cancel = (
            tmp_cancel.groupby([cat_var, "weather"])
            .size()
            .reset_index(name="count")
        )

        pivot_cancel = weather_counts_cancel.pivot(
            index=cat_var, columns="weather", values="count"
        ).fillna(0)

        # Reindex to match unified ordering
        pivot_cancel = pivot_cancel.reindex(category_order).fillna(0)

        pivot_cancel_pct = pivot_cancel.div(pivot_cancel.sum(axis=1), axis=0) * 100
        pivot_cancel_pct = pivot_cancel_pct.round(2)

    # ========== COUNTS: ALL vs CANCELED side-by-side ==========
    st.write("#### (b1) Weather counts by category (ALL vs CANCELED)")

    col_count_all, col_count_cancel = st.columns(2)

    with col_count_all:
        st.write("Counts (ALL bookings)")
        st.dataframe(pivot_all)

        fig_w_all, ax_w_all = plt.subplots(figsize=(6, 4))
        bottoms = np.zeros(len(pivot_all))
        for w in pivot_all.columns:
            vals = pivot_all[w].values
            ax_w_all.bar(category_order, vals, bottom=bottoms, label=w)
            bottoms += vals

        ax_w_all.set_title(f"Weather count by {cat_var} (ALL)")
        ax_w_all.set_xlabel(cat_var)
        ax_w_all.set_ylabel("Count")
        ax_w_all.grid(axis="y", alpha=0.3)
        ax_w_all.legend(title="Weather", fontsize=8, bbox_to_anchor=(1.05, 1), loc="upper left")
        plt.xticks(rotation=45, ha="right")
        st.pyplot(fig_w_all)

    with col_count_cancel:
        st.write("Counts (CANCELED only)")
        if pivot_cancel is None:
            st.info("No canceled records.")
        else:
            st.dataframe(pivot_cancel)

            fig_w_cancel, ax_w_cancel = plt.subplots(figsize=(6, 4))
            bottoms_c = np.zeros(len(pivot_cancel))
            for w in pivot_cancel.columns:
                vals = pivot_cancel[w].values
                ax_w_cancel.bar(category_order, vals, bottom=bottoms_c, label=w)
                bottoms_c += vals

            ax_w_cancel.set_title(f"Weather count by {cat_var} (CANCELED)")
            ax_w_cancel.set_xlabel(cat_var)
            ax_w_cancel.set_ylabel("Count")
            ax_w_cancel.grid(axis="y", alpha=0.3)
            ax_w_cancel.legend(title="Weather", fontsize=8, bbox_to_anchor=(1.05, 1), loc="upper left")
            plt.xticks(rotation=45, ha="right")
            st.pyplot(fig_w_cancel)

    # ========== PERCENTAGES: ALL vs CANCELED side-by-side ==========
    st.write("#### (b2) Weather percentage within category (ALL vs CANCELED)")

    col_pct_all, col_pct_cancel = st.columns(2)

    with col_pct_all:
        st.write("Percentages (ALL bookings)")
        st.dataframe(pivot_all_pct)

        fig_w_all_pct, ax_w_all_pct = plt.subplots(figsize=(6, 4))
        bottoms_pct = np.zeros(len(pivot_all_pct))
        for w in pivot_all_pct.columns:
            vals = pivot_all_pct[w].values
            ax_w_all_pct.bar(category_order, vals, bottom=bottoms_pct, label=w)
            bottoms_pct += vals

        ax_w_all_pct.set_title(f"Weather % by {cat_var} (ALL)")
        ax_w_all_pct.set_xlabel(cat_var)
        ax_w_all_pct.set_ylabel("Percentage (%)")
        ax_w_all_pct.grid(axis="y", alpha=0.3)
        ax_w_all_pct.legend(title="Weather", fontsize=8, bbox_to_anchor=(1.05, 1), loc="upper left")
        plt.xticks(rotation=45, ha="right")
        st.pyplot(fig_w_all_pct)

    with col_pct_cancel:
        st.write("Percentages (CANCELED only)")
        if pivot_cancel_pct is None:
            st.info("No canceled records.")
        else:
            st.dataframe(pivot_cancel_pct)

            fig_w_cancel_pct, ax_w_cancel_pct = plt.subplots(figsize=(6, 4))
            bottoms_c_pct = np.zeros(len(pivot_cancel_pct))
            for w in pivot_cancel_pct.columns:
                vals = pivot_cancel_pct[w].values
                ax_w_cancel_pct.bar(category_order, vals, bottom=bottoms_c_pct, label=w)
                bottoms_c_pct += vals

            ax_w_cancel_pct.set_title(f"Weather % by {cat_var} (CANCELED)")
            ax_w_cancel_pct.set_xlabel(cat_var)
            ax_w_cancel_pct.set_ylabel("Percentage (%)")
            ax_w_cancel_pct.grid(axis="y", alpha=0.3)
            ax_w_cancel_pct.legend(title="Weather", fontsize=8, bbox_to_anchor=(1.05, 1), loc="upper left")
            plt.xticks(rotation=45, ha="right")
            st.pyplot(fig_w_cancel_pct)

# ========= 4. Numerical Variable Explorer =========
st.subheader("② Numerical Variable: Distribution + Weather Scatter Plot View")

num_cols = [
    "lead_time", "stays_in_weekend_nights", "stays_in_week_nights",
    "adults", "children", "babies", "adr", "days_in_waiting_list",
    "total_of_special_requests"
]






num_var = st.selectbox("Choose a Numerical Variable:", num_cols, index=0)

if f.empty:
    st.warning("Filtered dataset is empty — adjust filter selections.")
else:
    # ---- 4.1 Histogram for canceled vs not canceled ----
    fig2, ax2 = plt.subplots(figsize=(8, 4))

    canceled = f[f["is_canceled"] == 1][num_var].dropna()
    not_canceled = f[f["is_canceled"] == 0][num_var].dropna()

    bins = 30
    ax2.hist(not_canceled, bins=bins, alpha=0.6, label="Not canceled")
    ax2.hist(canceled, bins=bins, alpha=0.6, label="Canceled")

    ax2.set_title(f"Distribution of {num_var} by Cancellation Status")
    ax2.set_xlabel(num_var)
    ax2.set_ylabel("Count")
    ax2.legend()
    ax2.grid(alpha=0.3)

    st.pyplot(fig2)

    # ---- 4.2 Weather-conditioned scatter: ALL vs CANCELED ----
    st.write("(b1) Numerical values vs Weather (ALL bookings)")

    tmpn = f.copy()
    tmpn["weather"] = tmpn["weather"].fillna("Unknown_weather")
    tmpn = tmpn.dropna(subset=[num_var, "weather"])

    # Top-8 weather types among ALL bookings
    top_weathers_n = (
        tmpn["weather"]
        .value_counts()
        .head(8)
        .index
        .tolist()
    )
    tmpn_all = tmpn[tmpn["weather"].isin(top_weathers_n)].copy()

    weather_order = top_weathers_n
    x_map = {w: i for i, w in enumerate(weather_order)}
    tmpn_all["x_pos"] = tmpn_all["weather"].map(x_map)

    max_points_per_weather = 500
    sampled_rows_all = []
    for w in weather_order:
        sub = tmpn_all[tmpn_all["weather"] == w]
        if len(sub) > max_points_per_weather:
            sub = sub.sample(max_points_per_weather, random_state=42)
        sampled_rows_all.append(sub)
    tmpn_all_plot = pd.concat(sampled_rows_all, ignore_index=True)

    jitter_all = np.random.uniform(-0.2, 0.2, size=len(tmpn_all_plot))
    x_vals_all = tmpn_all_plot["x_pos"].values + jitter_all
    y_vals_all = tmpn_all_plot[num_var].values

    fig3, ax3 = plt.subplots(figsize=(10, 5))
    ax3.scatter(x_vals_all, y_vals_all, alpha=0.3, s=10)
    ax3.set_xticks(range(len(weather_order)))
    ax3.set_xticklabels(weather_order, rotation=45, ha="right")
    ax3.set_xlabel("Weather")
    ax3.set_ylabel(num_var)
    ax3.set_title(f"{num_var} across Top-8 Weather Categories (ALL bookings)")
    ax3.grid(alpha=0.3)
    st.pyplot(fig3)

    # Summary table for ALL
    summary_all = (
        tmpn_all.groupby("weather")[num_var]
                .agg(["count", "mean", "median", "std"])
                .loc[weather_order]
                .round(2)
    )
    st.write("Summary table for numerical variable by weather (ALL bookings):")
    st.dataframe(summary_all)

    # ---- CANCELED ONLY ----
    st.write("(b2) Numerical values vs Weather (CANCELED bookings only)")

    tmpn_cancel = tmpn[tmpn["is_canceled"] == 1].copy()
    tmpn_cancel = tmpn_cancel[tmpn_cancel["weather"].isin(weather_order)]

    if tmpn_cancel.empty:
        st.info("No canceled bookings with these weather types in the current filter.")
    else:
        tmpn_cancel["x_pos"] = tmpn_cancel["weather"].map(x_map)

        sampled_rows_cancel = []
        for w in weather_order:
            sub = tmpn_cancel[tmpn_cancel["weather"] == w]
            if len(sub) > max_points_per_weather:
                sub = sub.sample(max_points_per_weather, random_state=42)
            sampled_rows_cancel.append(sub)
        tmpn_cancel_plot = pd.concat(sampled_rows_cancel, ignore_index=True)

        jitter_cancel = np.random.uniform(-0.2, 0.2, size=len(tmpn_cancel_plot))
        x_vals_c = tmpn_cancel_plot["x_pos"].values + jitter_cancel
        y_vals_c = tmpn_cancel_plot[num_var].values

        fig4, ax4 = plt.subplots(figsize=(10, 5))
        ax4.scatter(x_vals_c, y_vals_c, alpha=0.3, s=10, color="tab:red")
        ax4.set_xticks(range(len(weather_order)))
        ax4.set_xticklabels(weather_order, rotation=45, ha="right")
        ax4.set_xlabel("Weather")
        ax4.set_ylabel(num_var)
        ax4.set_title(f"{num_var} across Top-8 Weather Categories (CANCELED only)")
        ax4.grid(alpha=0.3)
        st.pyplot(fig4)

        summary_cancel = (
            tmpn_cancel.groupby("weather")[num_var]
                       .agg(["count", "mean", "median", "std"])
                       .loc[weather_order]
                       .round(2)
        )
        st.write("Summary table for numerical variable by weather (CANCELED only):")
        st.dataframe(summary_cancel)

    st.markdown(
        f"- The two scatter plots and summary tables above compare **{num_var}** across weather groups,\n"
        "  first using all bookings, then restricted to canceled bookings only.\n"
        "- This helps assess whether certain weather conditions are associated with longer lead times,\n"
        "  higher ADR, or other behavioral differences specifically among cancellations."
    )
