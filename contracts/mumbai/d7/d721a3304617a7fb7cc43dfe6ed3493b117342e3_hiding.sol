/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

contract hiding{
    string private secret;
    string public non_secret;
    string internal internal_string;

    constructor(){
        secret = "secret";
        non_secret = "non_secret";
        internal_string = "internal_string";
    }
}