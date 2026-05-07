// ============================================================
// House Signs — Supabase version
//
// Setup:
//   npm install @supabase/supabase-js
//   Fill in SUPABASE_URL and SUPABASE_ANON_KEY below (or use env vars).
//   Run schema.sql in the Supabase SQL editor first.
// ============================================================

import { useState, useEffect, useCallback, useRef } from "react";
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://cfgxeuckzvlehsyohlez.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmZ3hldWNrenZsZWhzeW9obGV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNzAxMDksImV4cCI6MjA5MzY0NjEwOX0.r8J-bbFqOH521mCR7iMY_J_kaP_N6Ph3hJ8eTjPJXQg";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const PALETTES = [
  { off: "#e8443a", on: "#2a9d5c" },
  { off: "#d4763b", on: "#2e7d8c" },
  { off: "#8b5e3c", on: "#4a7c59" },
  { off: "#b5485f", on: "#3a7ca5" },
  { off: "#7c6144", on: "#5b8a72" },
  { off: "#a0522d", on: "#2e8b57" },
];

function timeAgo(ts) {
  if (!ts) return "";
  const diff = Date.now() - new Date(ts).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

// ---------- Hooks ----------

function useAuth() {
  const [session, setSession] = useState(null);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const { data } = await supabase.auth.getSession();
      setSession(data.session);
      setUser(data.session?.user || null);
      setLoading(false);
    })();

    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      setSession(session);
      setUser(session?.user || null);
    });

    return () => data?.subscription?.unsubscribe();
  }, []);

  return { session, user, loading };
}

function useLongPress(callback, ms) {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  return useCallback((node) => {
    if (!node) return;
    let timer = null;
    const start = () => { timer = setTimeout(() => callbackRef.current(), ms); };
    const cancel = () => { if (timer) clearTimeout(timer); };
    node.addEventListener("pointerdown", start);
    node.addEventListener("pointerup", cancel);
    node.addEventListener("pointerleave", cancel);
    return () => {
      node.removeEventListener("pointerdown", start);
      node.removeEventListener("pointerup", cancel);
      node.removeEventListener("pointerleave", cancel);
    };
  }, [ms]);
}

// ---------- Components ----------

function AuthModal({ mode, onModeToggle, onSignUp, onSignIn, loading, error }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const isSignUp = mode === "signup";
  const canSubmit = isSignUp
    ? email.trim() && password && confirmPassword && password === confirmPassword
    : email.trim() && password;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (isSignUp) {
      onSignUp(email.trim(), password);
    } else {
      onSignIn(email.trim(), password);
    }
  };

  return (
    <div style={styles.modalOverlay}>
      <div style={styles.modal}>
        <h2 style={styles.modalTitle}>{isSignUp ? "Create Account" : "Sign In"}</h2>
        <form onSubmit={handleSubmit}>
          <input
            style={styles.input}
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoFocus
            disabled={loading}
          />
          <input
            style={styles.input}
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={loading}
          />
          {isSignUp && (
            <input
              style={styles.input}
              type="password"
              placeholder="Confirm Password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              disabled={loading}
            />
          )}
          {error && <p style={styles.errorText}>{error}</p>}
          <button
            style={{ ...styles.addBtn, opacity: canSubmit ? 1 : 0.4, width: "100%" }}
            disabled={!canSubmit || loading}
            type="submit"
          >
            {loading ? (isSignUp ? "Creating..." : "Signing in...") : isSignUp ? "Create Account" : "Sign In"}
          </button>
        </form>
        <button
          onClick={() => onModeToggle()}
          style={styles.toggleAuthModeBtn}
          disabled={loading}
        >
          {isSignUp ? "Already have an account? Sign in" : "Need an account? Sign up"}
        </button>
      </div>
    </div>
  );
}

function NicknameModal({ onSet, loading }) {
  const [val, setVal] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (val.trim()) onSet(val.trim());
  };

  return (
    <div style={styles.modalOverlay}>
      <div style={styles.modal}>
        <h2 style={styles.modalTitle}>What's your name?</h2>
        <p style={styles.namePromptHelp}>
          This is how others will see who flipped what.
        </p>
        <form onSubmit={handleSubmit}>
          <input
            style={styles.input}
            placeholder="Renee"
            value={val}
            onChange={(e) => setVal(e.target.value)}
            maxLength={20}
            autoFocus
            disabled={loading}
          />
          <button
            style={{ ...styles.addBtn, opacity: val.trim() ? 1 : 0.4, width: "100%" }}
            disabled={!val.trim() || loading}
            type="submit"
          >
            {loading ? "Saving..." : "Continue"}
          </button>
        </form>
      </div>
    </div>
  );
}

function HouseholdModal({ mode, onModeToggle, onCreate, onJoin, loading, error, onClose }) {
  const [val, setVal] = useState("");
  const isCreate = mode === "create";

  const handleSubmit = (e) => {
    e.preventDefault();
    if (val.trim()) {
      if (isCreate) onCreate(val.trim());
      else onJoin(val.trim());
    }
  };

  return (
    <div style={styles.modalOverlay} onClick={onClose}>
      <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
        <h2 style={styles.modalTitle}>{isCreate ? "Create a household" : "Join a household"}</h2>
        <form onSubmit={handleSubmit}>
          <input
            style={styles.input}
            placeholder={isCreate ? "e.g. Home" : "Invite code"}
            value={val}
            onChange={(e) => setVal(e.target.value)}
            autoFocus
            disabled={loading}
            maxLength={isCreate ? 40 : 8}
          />
          {error && <p style={styles.errorText}>{error}</p>}
          <button
            style={{ ...styles.addBtn, opacity: val.trim() ? 1 : 0.4, width: "100%" }}
            disabled={!val.trim() || loading}
            type="submit"
          >
            {loading ? (isCreate ? "Creating..." : "Joining...") : isCreate ? "Create" : "Join"}
          </button>
        </form>
        <button
          onClick={() => onModeToggle()}
          style={styles.toggleAuthModeBtn}
          disabled={loading}
        >
          {isCreate ? "Have a code? Join instead" : "Need to create? Create instead"}
        </button>
      </div>
    </div>
  );
}

function AddSignModal({ onAdd, onClose }) {
  const [label, setLabel] = useState("");
  const [emoji, setEmoji] = useState("📌");
  const [stateOff, setStateOff] = useState("");
  const [stateOn, setStateOn] = useState("");

  const emojiOptions = ["📌", "🐕", "🐱", "🗑️", "🧹", "💊", "🌱", "🔑", "🚪", "💡", "🧺", "📦", "🍼", "🛁", "🚗"];

  const handleSubmit = () => {
    if (!label.trim() || !stateOff.trim() || !stateOn.trim()) return;
    onAdd({
      label: label.trim(),
      emoji,
      state_off_label: stateOff.trim(),
      state_on_label: stateOn.trim(),
    });
  };

  return (
    <div style={styles.modalOverlay} onClick={onClose}>
      <div style={styles.modal} onClick={(e) => e.stopPropagation()}>
        <h2 style={styles.modalTitle}>New Sign</h2>
        <div style={styles.emojiPicker}>
          {emojiOptions.map((e) => (
            <button
              key={e}
              onClick={() => setEmoji(e)}
              style={{
                ...styles.emojiBtn,
                background: emoji === e ? "rgba(0,0,0,0.12)" : "transparent",
                transform: emoji === e ? "scale(1.2)" : "scale(1)",
              }}
            >
              {e}
            </button>
          ))}
        </div>
        <input
          style={styles.input}
          placeholder="Name (e.g. Trash)"
          value={label}
          onChange={(e) => setLabel(e.target.value)}
          maxLength={20}
          autoFocus
        />
        <div style={styles.stateInputs}>
          <input
            style={{ ...styles.input, ...styles.stateInput }}
            placeholder="Default (e.g. Full)"
            value={stateOff}
            onChange={(e) => setStateOff(e.target.value)}
            maxLength={16}
          />
          <span style={styles.arrow}>→</span>
          <input
            style={{ ...styles.input, ...styles.stateInput }}
            placeholder="Done (e.g. Taken out)"
            value={stateOn}
            onChange={(e) => setStateOn(e.target.value)}
            maxLength={16}
          />
        </div>
        <div style={styles.modalActions}>
          <button onClick={onClose} style={styles.cancelBtn}>Cancel</button>
          <button
            onClick={handleSubmit}
            style={{ ...styles.addBtn, opacity: label && stateOff && stateOn ? 1 : 0.4 }}
            disabled={!label || !stateOff || !stateOn}
          >
            Add Sign
          </button>
        </div>
      </div>
    </div>
  );
}

function SignCard({ sign, index, onToggle, onDelete }) {
  const [flipping, setFlipping] = useState(false);
  const [showDelete, setShowDelete] = useState(false);
  const palette = PALETTES[index % PALETTES.length];
  const bg = sign.active ? palette.on : palette.off;
  const stateLabel = sign.active ? sign.state_on_label : sign.state_off_label;

  const handleClick = () => {
    if (showDelete) { setShowDelete(false); return; }
    setFlipping(true);
    setTimeout(() => {
      onToggle(sign);
      setFlipping(false);
    }, 150);
  };

  const longPressRef = useLongPress(() => setShowDelete(true), 600);

  return (
    <div
      ref={longPressRef}
      onClick={handleClick}
      style={{
        ...styles.card,
        background: bg,
        transform: flipping ? "scale(0.94) rotateX(8deg)" : "scale(1) rotateX(0)",
      }}
    >
      {showDelete && (
        <button
          onClick={(e) => { e.stopPropagation(); onDelete(sign.id); }}
          style={styles.deleteBtn}
        >×</button>
      )}
      <div style={styles.cardEmoji}>{sign.emoji}</div>
      <div style={styles.cardLabel}>{sign.label}</div>
      <div style={styles.cardState}>{stateLabel}</div>
      {sign.last_changed_at && (
        <div style={styles.cardTime}>
          {sign.last_changed_by ? `${sign.last_changed_by} · ` : ""}
          {timeAgo(sign.last_changed_at)}
        </div>
      )}
    </div>
  );
}

// ---------- Main ----------

export default function HouseholdSigns() {
  const { session, user, loading: authLoadingInitial } = useAuth();
  const [signs, setSigns] = useState([]);
  const [loaded, setLoaded] = useState(false);
  const [showAdd, setShowAdd] = useState(false);
  const [authStep, setAuthStep] = useState("auth"); // "auth" | "nickname" | "done"
  const [authMode, setAuthMode] = useState("signin"); // "signin" | "signup"
  const [authError, setAuthError] = useState("");
  const [isAuthLoading, setIsAuthLoading] = useState(false);
  const [householdId, setHouseholdId] = useState(null);
  const [showHouseholdModal, setShowHouseholdModal] = useState(false);
  const [householdModalMode, setHouseholdModalMode] = useState("create"); // "create" | "join"
  const [householdError, setHouseholdError] = useState("");
  const [isHouseholdLoading, setIsHouseholdLoading] = useState(false);

  const displayName = user?.user_metadata?.display_name || user?.email || "";

  // Auth flow: determine which step user is on
  useEffect(() => {
    if (authLoadingInitial) return;
    if (!session) {
      setAuthStep("auth");
      setHouseholdId(null);
    } else if (!user?.user_metadata?.display_name) {
      setAuthStep("nickname");
      setHouseholdId(null);
    } else {
      setAuthStep("done");
    }
  }, [session, user, authLoadingInitial]);

  // Check for household membership when auth is done
  useEffect(() => {
    if (authStep !== "done" || !user) return;
    (async () => {
      const { data, error } = await supabase
        .from("household_members")
        .select("household_id")
        .eq("user_id", user.id)
        .limit(1);
      if (error) console.error(error);
      else if (data && data.length > 0) {
        setHouseholdId(data[0].household_id);
      } else {
        setHouseholdId(null);
      }
      setLoaded(true);
    })();
  }, [authStep, user]);

  // Load signs once household is selected
  useEffect(() => {
    if (!householdId) {
      setSigns([]);
      return;
    }
    (async () => {
      const { data, error } = await supabase
        .from("signs")
        .select("*")
        .eq("household_id", householdId)
        .order("position", { ascending: true });
      if (error) console.error(error);
      else setSigns(data || []);
    })();
  }, [householdId]);

  const handleSignUp = async (email, password) => {
    setAuthError("");
    setIsAuthLoading(true);
    const { error } = await supabase.auth.signUp({
      email,
      password,
    });
    setIsAuthLoading(false);
    if (error) {
      setAuthError(error.message);
    }
  };

  const handleSignIn = async (email, password) => {
    setAuthError("");
    setIsAuthLoading(true);
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    setIsAuthLoading(false);
    if (error) {
      setAuthError(error.message);
    }
  };

  const handleAuthModeToggle = () => {
    setAuthError("");
    setAuthMode(authMode === "signin" ? "signup" : "signin");
  };

  const handleNicknameSet = async (name) => {
    setIsAuthLoading(true);
    const { error } = await supabase.auth.updateUser({
      data: { display_name: name },
    });
    setIsAuthLoading(false);
    if (error) {
      console.error(error);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  const handleCreateHousehold = async (name) => {
    setHouseholdError("");
    setIsHouseholdLoading(true);
    const { data, error } = await supabase.rpc("create_household", {
      household_name: name,
    });
    setIsHouseholdLoading(false);
    if (error) {
      setHouseholdError(error.message);
    } else if (data) {
      setHouseholdId(data);
      setShowHouseholdModal(false);
    }
  };

  const handleJoinHousehold = async (code) => {
    setHouseholdError("");
    setIsHouseholdLoading(true);
    const { data, error } = await supabase.rpc("join_household", {
      invite_code: code,
    });
    setIsHouseholdLoading(false);
    if (error) {
      setHouseholdError(error.message);
    } else if (data) {
      setHouseholdId(data);
      setShowHouseholdModal(false);
    }
  };

  const handleHouseholdModalModeToggle = () => {
    setHouseholdError("");
    setHouseholdModalMode(householdModalMode === "create" ? "join" : "create");
  };

  // Realtime subscription — keeps every device in sync
  useEffect(() => {
    if (!householdId) return;
    const channel = supabase
      .channel(`signs-changes-${householdId}`)
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "signs", filter: `household_id=eq.${householdId}` },
        (payload) => {
          if (payload.eventType === "INSERT") {
            setSigns((prev) => [...prev, payload.new].sort((a, b) => a.position - b.position));
          } else if (payload.eventType === "UPDATE") {
            setSigns((prev) => prev.map((s) => s.id === payload.new.id ? payload.new : s));
          } else if (payload.eventType === "DELETE") {
            setSigns((prev) => prev.filter((s) => s.id !== payload.old.id));
          }
        }
      )
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [householdId]);

  const toggle = async (sign) => {
    if (!householdId) return;
    const newActive = !sign.active;
    const now = new Date().toISOString();

    // Optimistic update for snappy feel
    setSigns((prev) => prev.map((s) =>
      s.id === sign.id
        ? { ...s, active: newActive, last_changed_at: now, last_changed_by: displayName }
        : s
    ));

    // Update + log the flip in parallel
    const [{ error: updateErr }, { error: insertErr }] = await Promise.all([
      supabase.from("signs").update({
        active: newActive,
        last_changed_at: now,
        last_changed_by: displayName,
      }).eq("id", sign.id),
      supabase.from("sign_flips").insert({
        sign_id: sign.id,
        household_id: householdId,
        to_state: newActive,
        flipped_by: displayName,
      }),
    ]);

    if (updateErr || insertErr) console.error(updateErr || insertErr);
  };

  const addSign = async (data) => {
    if (!householdId) return;
    const maxPos = signs.reduce((m, s) => Math.max(m, s.position), -1);
    const { error } = await supabase.from("signs").insert({
      household_id: householdId,
      ...data,
      position: maxPos + 1,
    });
    if (error) console.error(error);
    setShowAdd(false);
  };

  const deleteSign = async (id) => {
    const { error } = await supabase.from("signs").delete().eq("id", id);
    if (error) console.error(error);
  };

  if (authLoadingInitial || authStep === "auth") {
    return (
      <AuthModal
        mode={authMode}
        onModeToggle={handleAuthModeToggle}
        onSignUp={handleSignUp}
        onSignIn={handleSignIn}
        loading={isAuthLoading}
        error={authError}
      />
    );
  }

  if (authStep === "nickname") {
    return <NicknameModal onSet={handleNicknameSet} loading={isAuthLoading} />;
  }

  if (!loaded) {
    return <div style={styles.container}><div style={styles.loading}>Loading…</div></div>;
  }

  // Show empty state if no household selected
  if (!householdId) {
    return (
      <div style={styles.container}>
        <link
          href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;500;700&family=DM+Serif+Display&display=swap"
          rel="stylesheet"
        />
        <header style={styles.header}>
          <h1 style={styles.title}>House Signs</h1>
          <p style={styles.subtitle}>
            {displayName}{" "}
            <button
              onClick={handleSignOut}
              style={styles.signOutBtn}
            >
              (sign out)
            </button>
          </p>
        </header>
        <div style={styles.emptyState}>
          <p style={styles.emptyStateText}>You're not part of a household yet.</p>
          <div style={styles.emptyStateButtons}>
            <button
              onClick={() => {
                setHouseholdModalMode("create");
                setShowHouseholdModal(true);
              }}
              style={styles.addBtn}
            >
              Create one
            </button>
            <button
              onClick={() => {
                setHouseholdModalMode("join");
                setShowHouseholdModal(true);
              }}
              style={styles.cancelBtn}
            >
              Join with a code
            </button>
          </div>
        </div>
        {showHouseholdModal && (
          <HouseholdModal
            mode={householdModalMode}
            onModeToggle={handleHouseholdModalModeToggle}
            onCreate={handleCreateHousehold}
            onJoin={handleJoinHousehold}
            loading={isHouseholdLoading}
            error={householdError}
            onClose={() => setShowHouseholdModal(false)}
          />
        )}
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <link
        href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;500;700&family=DM+Serif+Display&display=swap"
        rel="stylesheet"
      />
      <header style={styles.header}>
        <h1 style={styles.title}>House Signs</h1>
        <p style={styles.subtitle}>
          tap to flip · hold to delete · {displayName}{" "}
          <button
            onClick={handleSignOut}
            style={styles.signOutBtn}
          >
            (sign out)
          </button>
        </p>
      </header>
      <div style={styles.grid}>
        {signs.map((sign, i) => (
          <SignCard key={sign.id} sign={sign} index={i} onToggle={toggle} onDelete={deleteSign} />
        ))}
        <button onClick={() => setShowAdd(true)} style={styles.addCard}>
          <span style={styles.addIcon}>+</span>
          <span style={styles.addLabel}>Add Sign</span>
        </button>
      </div>
      {showAdd && <AddSignModal onAdd={addSign} onClose={() => setShowAdd(false)} />}
    </div>
  );
}

// ---------- Styles ----------

const styles = {
  container: {
    minHeight: "100vh",
    background: "#faf6f1",
    fontFamily: "'DM Sans', sans-serif",
    padding: "24px 16px 40px",
    maxWidth: 600,
    margin: "0 auto",
  },
  loading: { textAlign: "center", padding: "80px 0", color: "#999", fontSize: 16 },
  header: { textAlign: "center", marginBottom: 28 },
  title: {
    fontFamily: "'DM Serif Display', serif",
    fontSize: 32, fontWeight: 400, color: "#2c2520",
    margin: "0 0 4px", letterSpacing: "-0.5px",
  },
  subtitle: {
    fontSize: 13, color: "#a09080", margin: 0, fontWeight: 300,
    letterSpacing: "0.5px", fontStyle: "italic",
  },
  grid: { display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 14 },
  card: {
    position: "relative", borderRadius: 16, padding: "22px 16px 18px",
    cursor: "pointer", userSelect: "none", WebkitUserSelect: "none",
    display: "flex", flexDirection: "column", alignItems: "center", gap: 6,
    minHeight: 140, justifyContent: "center", color: "#fff",
    boxShadow: "0 2px 12px rgba(0,0,0,0.12), 0 1px 3px rgba(0,0,0,0.08)",
    WebkitTapHighlightColor: "transparent", perspective: "600px",
    transition: "transform 0.15s ease, background 0.3s ease",
  },
  cardEmoji: { fontSize: 32, lineHeight: 1 },
  cardLabel: {
    fontSize: 14, fontWeight: 500, letterSpacing: "0.5px",
    textTransform: "uppercase", opacity: 0.85,
  },
  cardState: {
    fontSize: 18, fontFamily: "'DM Serif Display', serif", fontWeight: 400,
    padding: "4px 14px", borderRadius: 20, marginTop: 2, letterSpacing: "0.3px",
    background: "rgba(255,255,255,0.2)",
  },
  cardTime: { fontSize: 11, opacity: 0.6, marginTop: 2, fontWeight: 300 },
  deleteBtn: {
    position: "absolute", top: 6, right: 8,
    background: "rgba(0,0,0,0.3)", border: "none", color: "#fff",
    width: 26, height: 26, borderRadius: "50%", fontSize: 18,
    cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
    lineHeight: 1, fontWeight: 700, padding: 0,
  },
  addCard: {
    borderRadius: 16, padding: "22px 16px", cursor: "pointer",
    display: "flex", flexDirection: "column", alignItems: "center",
    justifyContent: "center", gap: 6, minHeight: 140,
    background: "transparent", border: "2px dashed #ccc0b4",
    color: "#a09080", fontFamily: "'DM Sans', sans-serif",
  },
  addIcon: { fontSize: 28, fontWeight: 300, lineHeight: 1 },
  addLabel: { fontSize: 13, fontWeight: 500, letterSpacing: "0.3px" },
  modalOverlay: {
    position: "fixed", inset: 0, background: "rgba(0,0,0,0.45)",
    display: "flex", alignItems: "flex-end", justifyContent: "center",
    zIndex: 100, padding: 16, fontFamily: "'DM Sans', sans-serif",
  },
  modal: {
    background: "#faf6f1", borderRadius: "20px 20px 12px 12px",
    padding: "28px 24px 24px", width: "100%", maxWidth: 400,
  },
  modalTitle: {
    fontFamily: "'DM Serif Display', serif", fontSize: 22, fontWeight: 400,
    margin: "0 0 16px", color: "#2c2520", textAlign: "center",
  },
  namePromptHelp: {
    fontSize: 13, color: "#7a6a5a", textAlign: "center",
    margin: "0 0 16px", lineHeight: 1.5,
  },
  emojiPicker: {
    display: "flex", flexWrap: "wrap", gap: 4,
    justifyContent: "center", marginBottom: 16,
  },
  emojiBtn: {
    fontSize: 22, width: 38, height: 38, border: "none",
    borderRadius: 10, cursor: "pointer", display: "flex",
    alignItems: "center", justifyContent: "center",
    transition: "all 0.15s ease",
  },
  input: {
    width: "100%", padding: "12px 14px", border: "2px solid #ddd4ca",
    borderRadius: 12, fontSize: 16, fontFamily: "'DM Sans', sans-serif",
    background: "#fff", outline: "none", marginBottom: 12,
    boxSizing: "border-box", color: "#2c2520",
  },
  stateInputs: { display: "flex", alignItems: "center", gap: 8 },
  stateInput: { flex: 1, marginBottom: 0 },
  arrow: { color: "#a09080", fontSize: 18, flexShrink: 0 },
  modalActions: { display: "flex", gap: 10, marginTop: 20 },
  cancelBtn: {
    flex: 1, padding: "12px", border: "2px solid #ddd4ca",
    borderRadius: 12, background: "transparent", fontSize: 15,
    fontFamily: "'DM Sans', sans-serif", fontWeight: 500,
    cursor: "pointer", color: "#7a6a5a",
  },
  addBtn: {
    flex: 1, padding: "12px", border: "none", borderRadius: 12,
    background: "#2c2520", color: "#faf6f1", fontSize: 15,
    fontFamily: "'DM Sans', sans-serif", fontWeight: 500, cursor: "pointer",
  },
  signOutBtn: {
    background: "none", border: "none", color: "inherit",
    fontSize: "inherit", fontFamily: "inherit", cursor: "pointer",
    textDecoration: "underline", padding: 0,
  },
  errorText: {
    color: "#e8443a", fontSize: 13, marginBottom: 12, textAlign: "center",
  },
  toggleAuthModeBtn: {
    width: "100%", marginTop: 16, background: "none", border: "none",
    color: "#7a6a5a", fontSize: 13, fontFamily: "'DM Sans', sans-serif",
    cursor: "pointer", textDecoration: "underline",
  },
  emptyState: {
    display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
    flex: 1, padding: "40px 20px", textAlign: "center",
  },
  emptyStateText: {
    fontSize: 18, color: "#7a6a5a", marginBottom: 28, fontWeight: 300,
  },
  emptyStateButtons: {
    display: "flex", gap: 12, flexDirection: "column", width: "100%", maxWidth: 300,
  },
};
