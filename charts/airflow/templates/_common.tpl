{{- define "common_deployment" }}
        envFrom:
          - configMapRef:
              name: {{ .Release.Name }}-config-env
        volumeMounts:
          - name: "{{ .Release.Name }}-config-glob"
            mountPath: /tmp/config
      volumes:
      - name: {{ .Values.persistence.dags.name | quote }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.dags.name }}
      - name: {{ .Values.persistence.logs.name | quote }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.logs.name }}
      - name: "{{ .Release.Name }}-config-glob"
        configMap:
          name: {{ .Release.Name }}-config-glob
{{- end -}}
