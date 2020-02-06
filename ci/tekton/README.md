
Use these steps to trigger a Tekton pipeline build of your collections repository. The pipeline will build the collections and deploy a `pipelines-index` container into your cluster. The `pipelines-index` container hosts the Kabanero collections index file and related assets.

1. Deploy pipeline
    ```
    oc -n kabanero apply -f tekton/pipelines-build-task.yaml 
    ```

1. Configure security constraints for service account
    ```
    oc -n kabanero adm policy add-scc-to-user privileged -z pipelines-index
    ```

1. Create `pipelines-build-git-resource.yaml` file with the following contents. Modify `revision` and `url` properties as needed. 
    ```
    apiVersion: tekton.dev/v1alpha1
    kind: PipelineResource
    metadata:
      name: pipelines-build-git-resource
    spec:
      params:
      - name: revision
        value: master
      - name: url
        value: https://github.com/kabanero-io/kabanero-pipelines.git
      type: git
    ```

1. Deploy the `pipelines-build-git-resource.yaml` file via `oc -n kabanero apply -f pipelines-build-git-resource.yaml`

1. Create `pipelines-build-pipelinerun.yaml` file with the following contents.

    ```
    apiVersion: tekton.dev/v1alpha1
    kind: PipelineRun
    metadata:
      name: pipelines-build-pipelinerun
      namespace: kabanero
    spec:
      pipelineRef:
        name: pipelines-build-pipeline
      resources:
      - name: git-source
        resourceRef:
          name: pipelines-build-git-resource
      params:
        - name: registry
          value: foobar
      serviceAccount: pipelines-index
      timeout: 60m
    ```

1. If you are using GitHub Enterprise, [create a secret](https://github.com/tektoncd/pipeline/blob/master/docs/auth.md#basic-authentication-git) and associate it with the `pipelines-index` service account. For example:
    ```
    oc -n kabanero secrets link pipelines-index basic-user-pass
    ```

1. Trigger pipeline
    ```
    oc -n kabanero delete --ignore-not-found -f pipelines-build-pipelinerun.yaml
    sleep 5
    oc -n kabanero apply -f pipelines-build-pipelinerun.yaml
    ```

    You can track the pipeline execution in the Tekton dashboard or via CLI:
    ```
    oc -n kabanero logs $(oc -n kabanero get pod -o name -l tekton.dev/task=pipelines-build-task) --all-containers -f 
    ```

   After the build completes successfully, a `pipelines-index` container is deployed into your cluster.

1. Get the route for the `pipelines-index` pod and use it to generate a collections URL:

    ```
    COLLECTIONS_URL=$(oc -n kabanero get route pipelines-index --no-headers -o=jsonpath='http://{.status.ingress[0].host}/pipelines-index.yaml')
    echo $COLLECTIONS_URL
    ```

1. Follow the [configuring a Kabanero CR instance](https://kabanero.io/docs/ref/general/configuration/kabanero-cr-config.html) documentation to configure or deploy a Kabanero instance with the `COLLECTIONS_URL` obtained in the previous step. 
