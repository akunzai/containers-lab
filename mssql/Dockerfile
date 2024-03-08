# https://github.com/microsoft/mssql-docker/blob/master/linux/preview/examples/mssql-customize/
FROM mcr.microsoft.com/mssql/server:2022-latest

COPY --chmod=755 ./*.sh /

ENTRYPOINT ["/entrypoint.sh"]