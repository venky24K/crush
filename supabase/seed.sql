-- Mock Profiles Seed Data for Supabase
-- Run this in the Supabase SQL Editor to populate discovery profiles!

alter table public.profiles add column if not exists distance_km double precision default 5.0;

DO $$
DECLARE
    u1 uuid := gen_random_uuid();
    u2 uuid := gen_random_uuid();
    u3 uuid := gen_random_uuid();
    u4 uuid := gen_random_uuid();
    u5 uuid := gen_random_uuid();
BEGIN
    -- 1. Create Mock Auth Users
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES 
        (u1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'maya@crush.app', crypt('crush123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"name":"Maya Lin"}', now(), now()),
        (u2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'chloe@crush.app', crypt('crush123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"name":"Chloe Dupont"}', now(), now()),
        (u3, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'elena@crush.app', crypt('crush123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"name":"Elena Rostova"}', now(), now()),
        (u4, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sarah@crush.app', crypt('crush123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"name":"Sarah Chen"}', now(), now()),
        (u5, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'zara@crush.app', crypt('crush123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"name":"Zara Patel"}', now(), now())
    ON CONFLICT (id) DO NOTHING;

    -- 2. Insert Matching Profiles into public.profiles
    INSERT INTO public.profiles (id, email, full_name, birth_date, gender, looking_for, bio, occupation, school, photos, interests, city, distance_km, is_verified)
    VALUES
        (
            u1,
            'maya@crush.app',
            'Maya Lin',
            '1999-08-22',
            'female',
            ARRAY['male'],
            'Photographer traveling the world with a 35mm film camera. Tell me your top 3 songs and I will guess your favorite midnight snack 🎧🎞️',
            'Documentary Photographer',
            'RISD',
            ARRAY[
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80'
            ],
            ARRAY['Photography', 'Music Festivals', 'Travel & Adventure', 'Art & Museums', 'Coffee Lover'],
            'North Beach, SF',
            3.2,
            true
        ),
        (
            u2,
            'chloe@crush.app',
            'Chloe Dupont',
            '1997-03-10',
            'female',
            ARRAY['male'],
            'French expat in SF. Founder of a plant-based bakery 🌱🥐. Love sunset runs across Golden Gate and spontaneous weekend getaways.',
            'Pastry Chef & Founder',
            'Le Cordon Bleu Paris',
            ARRAY[
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80'
            ],
            ARRAY['Cooking', 'Foodie', 'Fitness & Gym', 'Wine Tasting', 'Dog Lover'],
            'Marina District, SF',
            4.8,
            true
        ),
        (
            u3,
            'elena@crush.app',
            'Elena Rostova',
            '2000-11-04',
            'female',
            ARRAY['male'],
            'AI researcher who spends too much time debating sci-fi paradoxes. Also teach salsa on Thursday nights 💃 Let us grab matcha!',
            'AI Research Scientist',
            'Stanford',
            ARRAY[
                'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=800&q=80'
            ],
            ARRAY['Coding & Tech', 'Dancing', 'Reading & Books', 'Coffee Lover', 'Startups & Business'],
            'Palo Alto / SF',
            8.5,
            true
        ),
        (
            u4,
            'sarah@crush.app',
            'Sarah Chen',
            '1998-07-19',
            'female',
            ARRAY['male'],
            'Ceramic artist & indie bookstore addict. Golden retriever mom (his name is Mochi 🐾). Looking for my concert buddy!',
            'Ceramicist & Illustrator',
            'CalArts',
            ARRAY[
                'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80'
            ],
            ARRAY['Dog Lover', 'Art & Museums', 'Music Festivals', 'Hiking & Outdoors', 'Board Games'],
            'Mission District, SF',
            2.1,
            false
        ),
        (
            u5,
            'zara@crush.app',
            'Zara Patel',
            '1996-12-01',
            'female',
            ARRAY['male'],
            'Bouldering, hot yoga, and hunting down the best street tacos in the bay 🌮 Always down for a board game tournament or comedy show.',
            'Product Manager',
            'UC Berkeley',
            ARRAY[
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80'
            ],
            ARRAY['Fitness & Gym', 'Yoga & Mindfulness', 'Foodie', 'Board Games', 'Travel & Adventure'],
            'Hayes Valley, SF',
            5.6,
            true
        )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        photos = EXCLUDED.photos,
        bio = EXCLUDED.bio,
        interests = EXCLUDED.interests;
END $$;
