from kfp.dsl import Input, Model, component


@component(
    base_image="gcr.io/deeplearning-platform-release/tf2-cpu.2-11:latest",
    packages_to_install=["google-cloud-aiplatform"],
)
def upload_model(
    model: Input[Model],
):
    from pathlib import Path

    from google.cloud import aiplatform

    aiplatform.init(project="my-project-9420-464616", location="us-central1")

    aiplatform.Model.upload_scikit_learn_model_file(
        model_file_path=model.path,
        display_name="IrisModelv3",
        project="my-project-9420-464616",
    )
