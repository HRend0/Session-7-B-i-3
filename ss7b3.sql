create schema ss7b3;
create table ss7b3.post (
post_id serial primary key,
user_id int,
content text,
is_public boolean default true,
tags text[],
created_at timestamp default current_timestamp
);

insert into ss7b3.post (user_id, content, is_public, tags, created_at)
select 
(random() * 1000)::int,
'bài đăng về chủ đề ' || case when i % 10 = 0 then 'Du Lịch' else 'đời sống' end || ' số ' || i,
case when i % 3 = 0 then false else true end,
case when i % 10 = 0 then array['travel', 'vlog'] else array['life', 'news'] end,
now() - (random() * interval '30 days') from generate_series(1, 100000) as i;

explain analyze 
select * from ss7b3.post 
where is_public = true and lower(content) ilike '%du lịch%';
create index idx_post_content_lower on ss7b3.post (lower(content));
explain analyze 
select * from ss7b3.post 
where is_public = true and lower(content) ilike '%du lịch%';
explain analyze 
select * from ss7b3.post where tags @> array['travel'];
create index idx_post_tags_gin on ss7b3.post using gin (tags);
explain analyze 
select * from ss7b3.post where tags @> array['travel'];
create index idx_post_public_recent on ss7b3.post (created_at desc) 
where is_public = true;
explain analyze 
select * from ss7b3.post 
where is_public = true and created_at >= now() - interval '7 days';
create index idx_post_user_recent on ss7b3.post (user_id, created_at desc);
explain analyze 
select * from ss7b3.post 
where user_id = 500 
order by created_at desc;

/* hiệu suất:
- expression index: giúp máy không phải tính toán hàm lower() cho từng dòng khi tìm kiếm.
- gin index: cực kỳ quan trọng khi làm việc với kiểu dữ liệu mảng (array) hoặc jsonb.
- partial index: giúp giảm kích thước tệp chỉ mục vì chỉ lưu những bài viết thỏa mãn is_public = true.
- composite index: tối ưu cho các truy vấn có cả lọc (where user_id) và sắp xếp (order by created_at).
*/