-- run like this:
--     psql -U postgres -v "password='...'" -f init.sql
drop database if exists wifiwardriving;
drop role if exists wifiwardriving;
create role wifiwardriving LOGIN PASSWORD :password;
create database wifiwardriving;
alter database wifiwardriving owner to wifiwardriving;
grant all on database wifiwardriving to wifiwardriving;
\c wifiwardriving;
create extension if not exists cube;
create extension if not exists earthdistance;
\c wifiwardriving wifiwardriving;
create table users (
    user_id serial primary key,
    username text unique not null,
    key bytea unique not null,
    salt bytea unique not null
);
create table datapoints (
    datapoint_id serial primary key,

    latitude double precision not null,
    longitude double precision not null,

    ssid text not null,
    auth_type varchar(32) not null,

    submitter int,
    constraint fk_submitter
        foreign key (submitter)
        references users(user_id),

    first_seen timestamp with time zone not null,
    last_seen timestamp with time zone not null
);
create table comments (
    comment_id serial primary key,
    content text not null,

    submitter int,
    constraint fk_submitter
        foreign key (submitter)
        references users(user_id),
        
    datapoint int,
    constraint fk_datapoint
        foreign key (datapoint)
        references datapoints(datapoint_id)
);

drop table if exists session;
