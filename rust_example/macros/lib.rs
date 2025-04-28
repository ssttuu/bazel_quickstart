//! An example Rust proc macro that logs function entry and exit using the
//! `tracing` crate.

use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, ItemFn};

/// A proc macro attribute that logs function entry and exit.
#[proc_macro_attribute]
pub fn log_function(_attr: TokenStream, item: TokenStream) -> TokenStream {
    // Parse the input function
    let input_fn = parse_macro_input!(item as ItemFn);

    let fn_name = &input_fn.sig.ident;
    let fn_block = &input_fn.block;
    let fn_inputs = &input_fn.sig.inputs;
    let fn_output = &input_fn.sig.output;
    let fn_vis = &input_fn.vis;
    let fn_generics = &input_fn.sig.generics;
    let is_async = input_fn.sig.asyncness.is_some();

    // Generate different implementations based on whether the function is async
    let expanded = if is_async {
        quote! {
            #fn_vis async fn #fn_name #fn_generics(#fn_inputs) #fn_output {
                tracing::info!("Entering async function: {}", stringify!(#fn_name));

                // Execute the original function body
                let result = async {
                    #fn_block
                }.await;

                tracing::info!("Exiting async function: {}", stringify!(#fn_name));

                result
            }
        }
    } else {
        quote! {
            #fn_vis fn #fn_name #fn_generics(#fn_inputs) #fn_output {
                tracing::info!("Entering function: {}", stringify!(#fn_name));

                // Execute the original function body
                let result = {
                    #fn_block
                };

                tracing::info!("Exiting function: {}", stringify!(#fn_name));

                result
            }
        }
    };

    // Convert back to TokenStream
    expanded.into()
}
