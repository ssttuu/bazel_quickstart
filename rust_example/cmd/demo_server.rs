//! Demo REST API server using Axum.

use std::net::SocketAddr;

use anyhow::{Context, Result};
use axum::extract::Path;
use axum::routing::get;
use axum::{Json, Router};
use chrono::Utc;
use clap::Parser;
use rust_example_api::model::User;
use rust_example_macros::log_function;

#[derive(Debug, Parser)]
struct Args {
    #[arg(short, long, env = "ADDRESS", default_value = "127.0.0.1:8080")]
    address: SocketAddr,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    tracing_subscriber::fmt::init();

    let app = Router::new()
        .route("/", get(get_root))
        .route("/{name}", get(get_user));

    tracing::info!("Starting server on {}", args.address);
    let listener = tokio::net::TcpListener::bind(args.address).await.unwrap();
    axum::serve(listener, app)
        .await
        .context("Failed to start the server")?;

    Ok(())
}

#[log_function]
async fn get_root() -> Json<User> {
    Json(User {
        name: "Unknown".to_string(),
        timestamp: Utc::now(),
    })
}

#[log_function]
async fn get_user(Path(name): Path<String>) -> Json<User> {
    Json(User {
        name,
        timestamp: Utc::now(),
    })
}
