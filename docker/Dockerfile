FROM pgxn/pgxn-tools:latest

RUN NO_CLUSTER=1 pg-start 17 postgresql-17-pgtap

ADD entrypoint.sh /usr/local/bin/

WORKDIR /pg_partman
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
