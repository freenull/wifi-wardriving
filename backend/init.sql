-- Authors:
-- - Jakub Utko

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

    bssid macaddr not null,
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

    submitter int not null,
    constraint fk_submitter
        foreign key (submitter)
        references users(user_id),
        
    datapoint int not null,
    constraint fk_datapoint
        foreign key (datapoint)
        references datapoints(datapoint_id)
);
create table achievements (
    achievement_id serial primary key,

    recipient int not null,
    constraint fk_recipient
        foreign key (recipient)
        references users(user_id),

    key text not null,
    unlock_time timestamp with time zone not null,

    unique (recipient, key)
);

drop table if exists session;
