pipeline{
   agent any
   stages{
      stage('SvcQC.Dep'){
         steps{
            sshagent(credentials:['o3as-ssh-kube']){
               sh "ssh -o StrictHostKeyChecking=no kube@o3api.test.fedcloud.eu \
               '([[ -d o3k8s ]] && (cd o3k8s && git pull) || git clone https://git.scc.kit.edu/synergy.o3as/o3k8s.git) &&\
                o3k8s/deploy --stage'"
          }
         }
       }
   }
}
