/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

contract hidingWithInput{
    string private secret;
    string public non_secret;
    string internal internal_string;

    constructor(string memory input1, string memory input2, string memory input3){
        secret = input1;
        non_secret = input2;
        internal_string = input3 ;
    }
}