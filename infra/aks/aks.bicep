@description('Specifies the location of AKS cluster.')
param location string

param githubRepository string

@description('Specifies the name of the AKS cluster.')
param aksClusterName string = 'akscluster'

// @description('Specifies the DNS prefix specified when creating the managed cluster.')
// param aksClusterDnsPrefix string = aksClusterName

@description('Specifies the tags of the AKS cluster.')
param aksClusterTags object = {
  resourceType: 'AKS Cluster'
  createdBy: 'ARM Template'
}

@allowed([
  'azure'
  'kubenet'
])
@description('Specifies the network plugin used for building Kubernetes network. - azure or kubenet.')
param aksClusterNetworkPlugin string = 'kubenet'

@allowed([
  'azure'
  'calico'
])
@description('Specifies the network policy used for building Kubernetes network. - calico or azure')
param aksClusterNetworkPolicy string = 'calico'

@description('Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param aksClusterPodCidr string = '10.244.0.0/16'

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param aksClusterServiceCidr string = '10.10.0.0/16'

@description('Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param aksClusterDnsServiceIP string = '10.10.0.10'

@description('Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param aksClusterDockerBridgeCidr string = '172.17.0.1/16'

@allowed([
  'basic'
  'standard'
])
@description('Specifies the sku of the load balancer used by the virtual machine scale sets used by nodepools.')
param aksClusterLoadBalancerSku string = 'standard'

@allowed([
  'Paid'
  'Free'
])
@description('Specifies the tier of a managed cluster SKU: Paid or Free')
param aksClusterSkuTier string = 'Paid'

@description('Specifies the version of Kubernetes specified when creating the managed cluster.')
param aksClusterKubernetesVersion string = '1.21.7'

@description('Specifies the administrator username of Linux virtual machines.')
param aksClusterAdminUsername string = 'adminuser'

@description('Specifies the SSH RSA public key string for the Linux nodes.')
param aksClusterSshPublicKey string

@description('Specifies whether enabling AAD integration.')
param aadEnabled bool = false

@description('Specifies the tenant id of the Azure Active Directory used by the AKS cluster for authentication.')
param aadProfileTenantId string = subscription().tenantId

@description('Specifies the AAD group object IDs that will have admin role of the cluster.')
param aadProfileAdminGroupObjectIDs array = []

@description('Specifies whether to create the cluster as a private cluster or not.')
param aksClusterEnablePrivateCluster bool = true

@description('Specifies whether to enable managed AAD integration.')
param aadProfileManaged bool = false

@description('Specifies whether to  to enable Azure RBAC for Kubernetes authorization.')
param aadProfileEnableAzureRBAC bool = false

@description('Specifies the unique name of the node pool profile in the context of the subscription and resource group.')
param nodePoolName string = 'nodepool1'

@description('Specifies the vm size of nodes in the node pool.')
param nodePoolVmSize string = 'Standard_DS3_v2'

@description('Specifies the OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified..')
param nodePoolOsDiskSizeGB int = 100

@description('Specifies the number of agents (VMs) to host docker containers. Allowed values must be in the range of 1 to 100 (inclusive). The default value is 1.')
param nodePoolCount int = 3

@allowed([
  'Linux'
  'Windows'
])
@description('Specifies the OS type for the vms in the node pool. Choose from Linux and Windows. Default to Linux.')
param nodePoolOsType string = 'Linux'

@description('Specifies the maximum number of pods that can run on a node. The maximum number of pods per node in an AKS cluster is 250. The default maximum number of pods per node varies between kubenet and Azure CNI networking, and the method of cluster deployment.')
param nodePoolMaxPods int = 30

@description('Specifies the maximum number of nodes for auto-scaling for the node pool.')
param nodePoolMaxCount int = 5

@description('Specifies the minimum number of nodes for auto-scaling for the node pool.')
param nodePoolMinCount int = 3

@description('Specifies whether to enable auto-scaling for the node pool.')
param nodePoolEnableAutoScaling bool = true

@allowed([
  'Spot'
  'Regular'
])
@description('Specifies the virtual machine scale set priority: Spot or Regular.')
param nodePoolScaleSetPriority string = 'Regular'

@description('Specifies the Agent pool node labels to be persisted across all nodes in agent pool.')
param nodePoolNodeLabels object = {}

@description('Specifies the taints added to new nodes during node pool create and scale. For example, key=value:NoSchedule. - string')
param nodePoolNodeTaints array = []

@allowed([
  'System'
  'User'
])
@description('Specifies the mode of an agent pool: System or User')
param nodePoolMode string = 'System'

@allowed([
  'VirtualMachineScaleSets'
  'AvailabilitySet'
])
@description('Specifies the type of a node pool: VirtualMachineScaleSets or AvailabilitySet')
param nodePoolType string = 'VirtualMachineScaleSets'

@description('Specifies the availability zones for nodes. Requirese the use of VirtualMachineScaleSets as node pool type.')
param nodePoolAvailabilityZones array = []

@description('Specifies the id of the virtual network.')
param virtualNetworkName string = 'spoke'
param hubVirtualNetworkName string = 'hub'
var aksSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, aksSubnetName)

@description('Specifies the name of the default subnet hosting the AKS cluster.')
param aksSubnetName string = 'AksSubnet'

var aadProfileConfiguration = {
  managed: aadProfileManaged
  enableAzureRBAC: aadProfileEnableAzureRBAC
  adminGroupObjectIDs: aadProfileAdminGroupObjectIDs
  tenantID: aadProfileTenantId
}

param logAnalyticsWorkspaceName string = 'lw-aks-workspace'

@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
@description('Specifies the service tier of the workspace: Free, Standalone, PerNode, Per-GB.')
param logAnalyticsSku string = 'PerGB2018'

@description('Specifies the workspace data retention in days. -1 means Unlimited retention for the Unlimited Sku. 730 days is the maximum allowed for all other Skus.')
param logAnalyticsRetentionInDays int = 60

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: logAnalyticsRetentionInDays
  }
}

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${aksClusterName}-user-assigned-mi'
  location: location
}

resource kubeletManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${aksClusterName}-kubelet-user-assigned-mi'
  location: location
}

var roleAssignmentName = guid(userAssignedManagedIdentity.id, resourceGroup().id)
resource aksRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleAssignmentName
  properties: {
    principalId: userAssignedManagedIdentity.properties.principalId
    roleDefinitionId: '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')}'
    principalType: 'ServicePrincipal'
  }
}

module acrResources 'acr/acr.bicep' = {
  name: 'acrResources'
  params: {
    kubeletManagedIdentityPrincipalId: kubeletManagedIdentity.properties.principalId
    location: location
    githubRepository: githubRepository
  }
}

var aksPrivateZoneName = 'privatelink.${location}.azmk8s.io'
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: aksPrivateZoneName
  location: 'global'

  resource  hubVnetLink 'virtualNetworkLinks' = {
    name: 'hubVnetLink'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: resourceId('Microsoft.Network/virtualNetworks', hubVirtualNetworkName)
      }
    }
  }

  resource  spokeVnetLink 'virtualNetworkLinks' = {
    name: 'spokeVnetLink'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
      }
    }
  }
}


resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity.id}': {}
    }
  }
  tags: aksClusterTags
  sku: {
    name: 'Basic'
    tier: aksClusterSkuTier
  }
  properties: {
    kubernetesVersion: aksClusterKubernetesVersion
    // dnsPrefix: aksClusterDnsPrefix
    //TODO nodeResourceGroup: ''

    identityProfile: {
      kubeletidentity: {
        clientId: kubeletManagedIdentity.properties.clientId
        objectId: kubeletManagedIdentity.properties.principalId
        resourceId: kubeletManagedIdentity.id
      }
    }
    agentPoolProfiles: [
      {
        name: toLower(nodePoolName)
        count: nodePoolCount
        vmSize: nodePoolVmSize
        osDiskSizeGB: nodePoolOsDiskSizeGB
        vnetSubnetID: aksSubnetId
        maxPods: nodePoolMaxPods
        osType: nodePoolOsType
        maxCount: nodePoolMaxCount
        minCount: nodePoolMinCount
        scaleSetPriority: nodePoolScaleSetPriority
        enableAutoScaling: nodePoolEnableAutoScaling
        mode: nodePoolMode
        type: nodePoolType
        availabilityZones: any(empty(nodePoolAvailabilityZones) ? null : nodePoolAvailabilityZones)
        nodeLabels: nodePoolNodeLabels
        nodeTaints: nodePoolNodeTaints
      }
    ]
    linuxProfile: {
      adminUsername: aksClusterAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: aksClusterSshPublicKey
          }
        ]
      }
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: aksClusterNetworkPlugin
      networkPolicy: aksClusterNetworkPolicy
      podCidr: aksClusterPodCidr
      serviceCidr: aksClusterServiceCidr
      dnsServiceIP: aksClusterDnsServiceIP
      dockerBridgeCidr: aksClusterDockerBridgeCidr
      loadBalancerSku: aksClusterLoadBalancerSku
    }
    aadProfile: (aadEnabled ? aadProfileConfiguration : null)
    apiServerAccessProfile: {
      enablePrivateCluster: aksClusterEnablePrivateCluster
      privateDNSZone: dnsZone.id
    }
    fqdnSubdomain: aksClusterName
  }
}

resource flux 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aksCluster
  properties: {
    extensionType: 'microsoft.flux'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    autoUpgradeMinorVersion: true
  }
}
