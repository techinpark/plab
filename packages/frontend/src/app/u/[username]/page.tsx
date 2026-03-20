import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import ProfilePageClient from './ProfilePageClient';

export const revalidate = 60;

async function getProfileData(username: string) {
  const baseUrl = process.env.NEXT_PUBLIC_URL 
    || (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : null)
    || 'http://localhost:3000';
  
  const res = await fetch(`${baseUrl}/api/users/${username}`, {
    next: { revalidate: 60 },
  });
  
  if (!res.ok) {
    return null;
  }
  
  return res.json();
}

export async function generateMetadata({ params }: { params: Promise<{ username: string }> }): Promise<Metadata> {
  const { username } = await params;
  const siteUrl = process.env.NEXT_PUBLIC_URL || 'http://localhost:3000';
  return {
    title: `@${username} - Token Usage | plab`,
    description: `View ${username}'s AI token usage statistics and cost breakdown on plab`,
    openGraph: {
      title: `@${username}'s Token Usage | plab`,
      description: `AI token usage statistics for ${username} on plab`,
      type: 'profile',
      url: `${siteUrl}/u/${username}`,
      siteName: 'plab',
      images: [
        {
          url: `${siteUrl}/og-image.png`,
          width: 1200,
          height: 630,
          alt: `${username}'s Token Usage on plab`,
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: `@${username}'s Token Usage | plab`,
      images: [`${siteUrl}/og-image.png`],
    },
  };
}

export default async function ProfilePage({ params }: { params: Promise<{ username: string }> }) {
  const { username } = await params;
  const data = await getProfileData(username);
  
  if (!data) {
    notFound();
  }
  
  return <ProfilePageClient initialData={data} username={username} />;
}
