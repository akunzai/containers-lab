# https://github.com/microsoft/mssql-docker/blob/master/linux/preview/examples/mssql-customize/
FROM mcr.microsoft.com/mssql/server:2022-latest

COPY --chmod=755 ./*.sh /

HEALTHCHECK --interval=10s --timeout=10s --start-period=10s --retries=5 \
	CMD /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]