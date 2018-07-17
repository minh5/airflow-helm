{{- define "common_deployment" }}
      {{- if .Values.extra.envs }}
        env:
        {{- range $key, $value := .Values.extra.envs }}
          - name: {{ $key | quote }}
            value: {{ $value | quote }}
        {{- end }}
      {{- end }}
        {{ if .Values.extra.secrets }}          
        envFrom:
        {{ range $var := .Values.secrets }}
          - secretRef:
              name: {{ $var | quote }}
        {{ end }}
        {{ end }}
        volumeMounts:
          - name: "{{ .Release.Name }}-config"
            mountPath: /tmp/config
      volumes:
      {{- if .Values.persistence.enabled }}          
      - name: {{ .Values.persistence.dags.name | quote }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.dags.name }}
      - name: {{ .Values.persistence.logs.name | quote }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.logs.name }}
      {{ end }}
      - name: "{{ .Release.Name }}-config"
        configMap:
          name: {{ .Release.Name }}-config
{{- end -}}
