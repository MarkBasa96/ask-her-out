-- Mark is the admin: he can see reports and hide pages from the dashboard's Admin tab.
-- The email is the one he signs in with (it's already public in ask-her-out.html's CONFIG).
insert into public.admins (email) values ('joemarkloarbasa96@gmail.com') on conflict do nothing;
