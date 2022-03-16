/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

contract Verify {
    string private greeting;

    function hello (bool sayHello)public pure returns(string memory){
        if(sayHello){
            return "Hello";
        }
        return "";
    }
}