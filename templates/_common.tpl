{{- define "common_deployment" }}
        env:
        - name: AIRFLOW_KUBE_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: SQL_ALCHEMY_CONN
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-secrets
              key: sql_alchemy_conn
        volumeMounts:
        - name: {{ .Release.Name }}-configmap
          mountPath: /root/airflow/airflow.cfg
          subPath: airflow.cfg
        - name: airflow-dags
          mountPath: /root/airflow/dags
        - name: airflow-logs
          mountPath: /root/airflow/logs
{{- end -}}
