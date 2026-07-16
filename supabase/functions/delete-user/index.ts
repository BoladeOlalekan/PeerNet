import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { firebaseUid } = await req.json()

    if (!firebaseUid) {
      return new Response(JSON.stringify({ error: 'Missing firebaseUid' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      })
    }

    // 1. Delete user from Supabase 'users' table
    const { error: dbError } = await supabase
      .from('users')
      .delete()
      .eq('firebase_uid', firebaseUid)

    if (dbError) {
      console.error('Supabase DB delete error:', dbError)
      return new Response(JSON.stringify({ error: dbError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      })
    }

    // 2. Try to delete user from Firebase Auth using Firebase Service Account credentials
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    let firebaseDeleted = false
    let firebaseError = null

    if (serviceAccountJson) {
      try {
        const credentials = JSON.parse(serviceAccountJson)
        const jose = await import("https://esm.sh/jose@4.14.4")
        
        const privateKey = await jose.importPKCS8(credentials.private_key, 'RS256')
        
        const jwt = await new jose.SignJWT({
          iss: credentials.client_email,
          scope: 'https://www.googleapis.com/auth/identitytoolkit',
          aud: 'https://oauth2.googleapis.com/token',
          exp: Math.floor(Date.now() / 1000) + 3600,
          iat: Math.floor(Date.now() / 1000)
        })
          .setProtectedHeader({ alg: 'RS256' })
          .sign(privateKey)

        // Exchange JWT for Access Token
        const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt
          })
        })

        if (!tokenRes.ok) {
          const text = await tokenRes.text()
          throw new Error('Failed to exchange Google OAuth token: ' + text)
        }

        const { access_token } = await tokenRes.json()

        // Call Identity Toolkit API to delete account
        const deleteRes = await fetch(`https://identitytoolkit.googleapis.com/v1/projects/${credentials.project_id}/accounts:delete`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${access_token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            localId: [firebaseUid]
          })
        })

        if (!deleteRes.ok) {
          const text = await deleteRes.text()
          throw new Error('Failed to delete user in Firebase: ' + text)
        }

        firebaseDeleted = true
      } catch (err) {
        console.error('Firebase Auth delete error:', err)
        firebaseError = err.message
      }
    } else {
      console.warn('FIREBASE_SERVICE_ACCOUNT env variable is not set. Skipping Firebase Auth deletion.')
    }

    return new Response(JSON.stringify({
      success: true,
      supabaseDeleted: true,
      firebaseDeleted,
      firebaseError
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })

  } catch (err) {
    console.error('Function error:', err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    })
  }
})
