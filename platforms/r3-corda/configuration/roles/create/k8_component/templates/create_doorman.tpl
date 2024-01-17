apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  annotations:
    fluxcd.io/automated: "false"
  namespace: {{ component_ns }}
spec:
  releaseName: {{ component_name }}
  interval: 1m
  chart:
    spec:
      chart: {{ org.gitops.chart_source }}/{{ chart }}
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
  values:
    nodeName: {{ component_name }}
    metadata:
      namespace: {{component_ns }}
    image:
      authusername: sa
      containerName: {{ network.docker.url }}/bevel-doorman-linuxkit:latest
      env:
      - name: DOORMAN_PORT
        value: 8080
      - name: DOORMAN_ROOT_CA_NAME
        value: {{ services.doorman.subject }}
      - name: DOORMAN_TLS
        value: {{ chart_tls }}
      - name: DOORMAN_DB
        value: /opt/doorman/db
      - name: DOORMAN_AUTH_USERNAME
        value: sa
      - name: DB_URL
        value: mongodb-{{ component_name }}
      - name: DB_PORT
        value: 27017
      - name: DATABASE
        value: admin
      - name: DB_USERNAME
        value: {{ component_name }}
{% if network.docker.username is defined %}
      imagePullSecret: regcred
{% endif %}
      tlsCertificate: {{ chart_tls }}
      initContainerName: {{ network.docker.url }}/alpine-utils:1.0
      mountPath:
        basePath: /opt/doorman
    storage:
      memory: 512Mi
      name: {{ sc_name }}
    mountPath:
      basePath: /opt/doorman
    vault:
      address: {{ vault.url }}
      role: vault-role
      authpath: {{ component_auth }}
      serviceaccountname: vault-auth
      certsecretprefix: {{ component_name }}/data/{{ component_name }}/certs
      dbcredsecretprefix: {{ component_name }}/data/{{ component_name }}/credentials/mongodb
      secretdoormanpass: {{ component_name }}/data/{{ component_name }}/credentials/userpassword
      tlscertsecretprefix: {{ component_name }}/data/{{ component_name }}/tlscerts
      dbcertsecretprefix: {{ component_name }}/data/{{ component_name }}/certs
    healthcheck:
      readinesscheckinterval: 10
      readinessthreshold: 15
      dburl: mongodb-{{ component_name }}:27017
    service:
      port: {{ services.doorman.ports.servicePort }}
      targetPort: {{ services.doorman.ports.targetPort }}
{% if services.doorman.ports.nodePort is defined %}
      type: NodePort
      nodePort: {{ services.doorman.ports.nodePort }}
{% else %}
      type: ClusterIP
{% endif %}
      annotations: {}
    deployment:
      annotations: {}
    pvc:
      annotations: {}
{% if network.env.proxy == 'ambassador' %}
    ambassador:
      external_url_suffix: {{item.external_url_suffix}}
{% endif %}
