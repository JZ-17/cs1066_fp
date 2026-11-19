import Foundation

/// Where the app talks to Supabase.
///
/// The publishable key is meant to ship inside the app. It gets you as far as
/// the door and no further. Which rows you can actually read is decided by the
/// row level security policies in supabase/migrations, which pin every deck to
/// the account that made it.
///
/// The secret key is a different thing entirely. It ignores every one of those
/// policies, so it must never appear in this file, in the app, or in git. It
/// lives in `supabase secrets set` and is only ever read by an Edge Function.
enum SupabaseConfig {

    static let url = URL(string: "https://ckivudtwicyyikslzlfo.supabase.co")!

    /// Project Settings > API > publishable key, starting with `sb_publishable_`.
    static let publishableKey = "sb_publishable_TxTcW5CcRNHyfKI6R_aYAA_u-3Hzzmg"

    /// False until the key above is filled in.
    ///
    /// The app checks this before it tries to reach the network. Without it, a
    /// fresh clone of the repo would hang on a doomed request at launch. With
    /// it, the game still plays on the three built in decks and only the
    /// custom deck features are switched off.
    static var isConfigured: Bool {
        !publishableKey.hasPrefix("PASTE_") && !publishableKey.isEmpty
    }
}
