FROM bash
WORKDIR /app
COPY ./bluser.sh /app
CMD ["/app/bluser.sh" ]
