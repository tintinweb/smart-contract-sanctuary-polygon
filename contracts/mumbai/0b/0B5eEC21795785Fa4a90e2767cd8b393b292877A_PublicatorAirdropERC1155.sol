/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// File: contracts/PublicatorAirdropERC1155.sol



pragma solidity ^0.8.0;
/**
        __________     ___.   .__  .__               __                
        \______   \__ _\_ |__ |  | |__| ____ _____ _/  |_  ___________ 
        |     ___/  |  \ __ \|  | |  |/ ___\\__  \\   __\/  _ \_  __ \
        |    |   |  |  / \_\ \  |_|  \  \___ / __ \|  | (  <_> )  | \/
        |____|   |____/|___  /____/__|\___  >____  /__|  \____/|__|   
                            \/             \/     \/                   
 */
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract PublicatorAirdropERC1155 {
    constructor() {}

    function airdropNft(
        IERC1155 _token,
        address[] calldata _to,
        uint256[] calldata _id,
        uint256[] calldata _amount
    ) public {
        require(
            _to.length == _id.length,
            "Receivers and IDs are different length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
        }
    }
}