//! This module defines the data model for the API.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Represents a user in the system.
#[derive(Debug, Serialize, Deserialize)]
pub struct User {
    /// The name of the user.
    pub name: String,

    /// The timestamp when the user was created or last updated.
    pub timestamp: DateTime<Utc>,
}
