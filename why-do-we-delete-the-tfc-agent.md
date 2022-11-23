# Why do we delete the TFC Cloud Agent after each run?
An obvious first question when looking at this workflow is **why** do we configure a terraform-post-apply hook to delete the agent once the apply has finished?

Surely if the Terraform Cloud agent is running in 'Single-Execution Mode' then nothing is persisted between Terraform Cloud runs... right?

Wrong. In Single Execution mode, yes the container is restarted and therefore no storage is persisted between runs (great for stopping errors when Terraform writes to the local filesystem), but somethings are still persisted... namely the Kubernetes MountedServiceAccount token.

This means that a Terraform plan or apply, which has access to a MountedServiceAccount token in the filesystem at `/var/run/secrets/kubernetes.io/serviceaccount/token`, has access to a  long lived persistent credential that will be valid for as long as the pod exists.

The scenario where someone can maliciously take advantage of this is as follows. 
- Someone is able to execute a Terraform plan or apply.
- They exfiltrate the credential from the execution environment.
- Now they have a long lived persistent token that they can use to make requests to Vault.
- You would have no ability to differentiate the bad actors requests from any other legitimate Terraform plan or apply. 
- The bad actor also inherits any change to the Vault policy that's made.

The reason this ServiceAccount token is persisted is one of the most commonly spoken about benefits of running containerized workloads. Once my container is running, its very limited as to what can change inside my container. Yielding the benefit of more predictable run times. However, one thing that you don't want to be static in your environment is your credentials.

You should be assuming a breach, and limiting the length of time any credential **can** be used if the worst happens.

So how do we cater to these competing priorities?
1. I want everything in my container to never change in order to give me predictability.
2. I need a credential in my container which needs to change frequently.

The answer to this question was addressed in Kubernetes version v.1.20 [Stable] with something called `ServiceAccount token volume projection`.

Service account token projection allows us to still keep our containers running in an immutable way, however, for a single location in the filesystem i can **project** a new token into it over time.

This also has the benefit that once the Pod is deleted the ServiceAccount token is invalidated. Meaning that if our Terraform Apply has a post-execution step to delete the pod that executed it, we are invalidating our own MountedServiceAccount token in the process.

Therefore, even if a bad actor did exfiltrate credentials, it would only be valid until the Terraform apply completed. Which is likely to be a matter of minutes (big deal...). This is why we delete the pod that ran our Terraform apply.

> Note: You can harden this process future still by running the same hook after every plan.

For further reading I recommnend you browse the the following resources.

References:
- [ServiceAccount Tokens in Pods Docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [ServiceAccount Token Volume Projection Docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#serviceaccount-token-volume-projection)
- [ServiceAccountTokenProjections API Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#serviceaccounttokenprojection-v1-core)
- [ServiceAccountTokens invalidatied once a Pod is deleted](https://github.com/kubernetes/website/blob/main/content/en/docs/tasks/configure-pod-container/configure-service-account.md?plain=1#L193:L194)
