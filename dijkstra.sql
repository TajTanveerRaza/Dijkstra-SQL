drop table if exists graph;
create table graph(source int,target int,weight int);
insert into graph values(0,1,2),(1,0,2),(0,4,10),(4,0,10),(1,3,3),(3,1,3),(1,4,7),(4,1,7),(2,3,4),(3,2,4),(3,4,5),(4,3,5),(4,2,6),(2,4,6);

create or replace function dijkstra(s int)
returns table(target int,distancetotarget int) as
$$
begin
    drop table if exists path;
    drop table if exists unvisited;
    create table unvisited(vertex int,value int);
    create table path(target int,distancetotarget int);
    insert into unvisited values(s,0);
    insert into unvisited select distinct (source),-1
                          from graph
                          where source<>s;
    perform weights(s);
    return query select * from path;
end;
$$ language plpgsql;

create or replace function weights(s int)
returns void as
$$
declare
    r record;
    x int;
    y int;
    z int;
    sum int;
begin
    drop table if exists temp;
    create table temp(vertex int,value int);
    insert into path select * from unvisited where vertex=s;
    delete from unvisited where vertex=s;
    if not exists(select * from unvisited)
        then return;
    end if;
    for r in select * from graph where source=s
    loop
        if r.target in (select vertex from unvisited)
            then x:=(select distancetotarget from path where target=s);
                 y:=r.weight;
                 sum:=x+y;
                 z:=(select value from unvisited where vertex=r.target);
                 if z=-1 or sum<z
                    then update unvisited set value=sum where vertex=r.target;
                 end if;
        end if;
    end loop;
    insert into temp select * from unvisited where value>=0;
    for r in select * from temp where value<=all(select value from temp)
    loop
        x:=r.vertex;
    end loop;
    perform weights(x);
    return;
end;
$$ language plpgsql;

select dijkstra(0);
select * from path;
