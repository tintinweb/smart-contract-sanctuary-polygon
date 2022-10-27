/**
 *Submitted for verification at polygonscan.com on 2022-10-27
*/

contract TheosFaucet {
    address public immutable token;

    constructor (address _token) {
        token = _token;
    }

    function get(address to, uint256 amount) external {
        (bool success, bytes memory d) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success);
    }
}