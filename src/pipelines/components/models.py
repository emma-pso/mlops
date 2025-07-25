from kfp.dsl import Dataset, Input, Metrics, Model, Output, component


@component(
    # Update the base image for a compatible Python version
    base_image="gcr.io/deeplearning-platform-release/tf-cpu.2-11:latest",
    packages_to_install=[
        "pandas",
        "joblib",
        "scikit-learn",  # Add scikit-learn for accuracy_score
        "kfp",  # Explicitly add kfp for good practice
    ],
)
def decision_tree(
    train_dataset: Input[Dataset],
    metrics: Output[Metrics],
    output_model: Output[Model],
):
    import joblib
    import pandas as pd
    from sklearn.metrics import accuracy_score
    from sklearn.model_selection import train_test_split
    from sklearn.tree import DecisionTreeClassifier

    train = pd.read_csv(train_dataset.path)

    X_train, X_test, y_train, y_test = train_test_split(
        train.drop("Species", axis=1),
        train["Species"],
        test_size=0.2,
        random_state=42,
    )

    model = DecisionTreeClassifier()
    model.fit(X_train, y_train)
    pred = model.predict(X_test)
    acc = accuracy_score(y_test, pred)

    metrics.log_metric("accuracy", (acc))

    joblib.dump(model, output_model.path)


@component(
    # Update the base image for a compatible Python version
    base_image="gcr.io/deeplearning-platform-release/tf-cpu.2-11:latest",
    packages_to_install=[
        "pandas",
        "joblib",
        "scikit-learn",  # Add scikit-learn for accuracy_score
        "kfp",  # Explicitly add kfp for good practice
    ],
)
def random_forest(
    train_dataset: Input[Dataset],
    metrics: Output[Metrics],
    output_model: Output[Model],
):
    import joblib
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score, roc_auc_score
    from sklearn.model_selection import train_test_split

    train = pd.read_csv(train_dataset.path)

    X_train, X_test, y_train, y_test = train_test_split(
        train.drop("Species", axis=1),
        train["Species"],
        test_size=0.2,
        random_state=42,
    )

    model = RandomForestClassifier()
    model.fit(X_train, y_train)
    pred = model.predict(X_test)
    acc = accuracy_score(y_test, pred)

    metrics.log_metric("accuracy", (acc))

    joblib.dump(model, output_model.path)
