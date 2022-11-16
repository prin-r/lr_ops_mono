use obi::{OBIDecode, OBIEncode, OBISchema};
use owasm_kit::{execute_entry_point, ext, oei, prepare_entry_point};
use hex;

const DS_ID: i64 = 537;

#[derive(OBIDecode, OBISchema)]
struct Input {
    collection: Vec<u8>,
    encoded_token_ids: Vec<u8>,
}

#[derive(OBIEncode, OBISchema)]
struct Output {
    flagged_status: Vec<u8>
}

fn prepare_impl(input: Input) {
    if input.encoded_token_ids.len() == 0 || input.encoded_token_ids.len() % 32 != 0 {
        panic!("Error wrong format for encoded_token_ids");
    }

    if input.collection.len() != 20 {
        panic!("Error collection must be 20 bytes");
    }

    oei::ask_external_data(
        (input.encoded_token_ids.len() * 1000 + input.collection.len()) as i64,
        DS_ID,
        format!("{} {}", hex::encode(&input.collection), hex::encode(&input.encoded_token_ids)).as_bytes()
    );
}

fn execute_impl(input: Input) -> Output {
    let res = ext::load_majority::<String>((input.encoded_token_ids.len() * 1000 + input.collection.len()) as i64).unwrap();
    assert_eq!(res.len() * 32, input.encoded_token_ids.len());

    Output {
        flagged_status: (&res.split("").collect::<Vec<&str>>()[1..res.len()+1])
            .to_vec()
            .iter()
            .map(|&x| match x {"0" => 0, "1" => 1, _ => panic!("Unknown flag")})
            .collect()
    }
}

prepare_entry_point!(prepare_impl);
execute_entry_point!(execute_impl);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_convert_to_output() {
        let res: String = "11100".to_string();
        assert_eq!(
            vec![1u8, 1u8, 1u8, 0u8, 0u8],
            (&res.split("").collect::<Vec<&str>>()[1..res.len()+1])
                .to_vec()
                .iter()
                .map(|&x| match x {"0" => 0, "1" => 1, _ => panic!("Unknown flag")})
                .collect::<Vec<u8>>()
        );
    }
}
