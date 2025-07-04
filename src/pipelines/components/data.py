from kfp.dsl import Dataset, Output, component


@component(
    base_image="gcr.io/deeplearning-platform-release/tf-cpu.2-11:latest",
    packages_to_install=["pandas", "google-cloud-bigquery", "scikit-learn", "kfp"],
)
def load_data(
    project_id: str,
    bq_dataset: str,
    bq_table: str,
    train_dataset: Output[Dataset],
    test_dataset: Output[Dataset],
):
    import pandas as pd
    from google.cloud import bigquery
    from sklearn.model_selection import train_test_split

    client = bigquery.Client(project=project_id)

    # More direct way to query BigQuery to a pandas DataFrame
    query = f"SELECT * FROM `{project_id}.{bq_dataset}.{bq_table}`"
    df = client.query(query).to_dataframe()

    df["Species"].replace(
        {
            "Iris-versicolor": 0,
            "Iris-virginica": 1,
            "Iris-setosa": 2,
        },
        inplace=True,
    )

    X_train, X_test, y_train, y_test = train_test_split(
        df.drop("Species", axis=1),
        df["Species"],
        test_size=0.2,
        random_state=42,
    )

    # Recombine features and target for saving
    train_df = X_train.copy()
    train_df["Species"] = y_train

    test_df = X_test.copy()
    test_df["Species"] = y_test

    train_df.to_csv(train_dataset.path, index=False)
    test_df.to_csv(test_dataset.path, index=False)
