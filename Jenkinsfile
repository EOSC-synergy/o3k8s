pipeline{
   agent any
   stages{
      stage('SvcQC.Dep'){
         steps{
            sshagent(credentials:['o3as-ssh-kube']){
               //sh "ssh -o StrictHostKeyChecking=no kube@o3api.test.fedcloud.eu \
               //'([[ -d o3k8s ]] && (cd o3k8s && git pull) || git clone https://codebase.helmholtz.cloud/m-team/o3as/o3k8s.git) &&\
               // o3k8s/deploy --stage'"
               sh "ssh -o StrictHostKeyChecking=no kube@o3api.test.fedcloud.eu \
               '([[ -d o3k8s ]] && (rm -rf o3k8s) &&\
                git clone -b ${env.BRANCH_NAME} https://codebase.helmholtz.cloud/m-team/o3as/o3k8s.git) &&\
                o3k8s/deploy --stage'"
          }
         }
       }
   }
}
