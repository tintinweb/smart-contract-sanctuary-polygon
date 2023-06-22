// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IEfforceWithDraw.sol";

contract EfforceWithdraw
    is IERC721TokenReceiver, IEfforceWithDraw
{
    bytes4 private constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    address public immutable GENESIS_PROJECT_1; // 0xC849AD758bF4F69A087Ce0dF164b3a4F28f4B49C;
    address public immutable GENESIS_PROJECT_2; // 0x6cC885Ca0E488f42a9397f923C53B270E2a728de;

    uint256 public immutable REFUND_1; // = 10;
    uint256 public immutable REFUND_2; // = 10;

    address public immutable REFUND_TOKEN; // = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public contractManager;

    mapping(address=>uint256) private accountToRefund;

    string constant private permissionError = "Permission denied";
    string constant private tokenNotSupported = "This token is not supported";
    string constant private refundNotAvailable = "Refund not available";

    constructor(
        address genesisProject1,
        uint256 refund1,
        address genesisProject2,
        uint256 refund2,
        address refundTokenAddress,
        address[] memory accounts,
        uint256[] memory refunds
    )
    {
        require(accounts.length == refunds.length);

        GENESIS_PROJECT_1 = genesisProject1;
        REFUND_1 = refund1;
        GENESIS_PROJECT_2 = genesisProject2;
        REFUND_2 = refund2;
        REFUND_TOKEN = refundTokenAddress;
        contractManager = msg.sender;

        for (uint i = 0; i < accounts.length; i++) {
            accountToRefund[accounts[i]] = refunds[i];
        }
    }

    function onERC721Received(address, address _from, uint256, bytes calldata)
        external
        override
        returns(bytes4)
    {
        require(msg.sender == GENESIS_PROJECT_1 || msg.sender == GENESIS_PROJECT_2, tokenNotSupported);

        uint256 refund;

        if (msg.sender == GENESIS_PROJECT_1) {
            refund = REFUND_1;
        } else {
            refund = REFUND_2;
        }

        IERC20(REFUND_TOKEN).transfer(_from, refund);

        return MAGIC_ON_ERC721_RECEIVED;
    }

    function withdraw(address beneficiary, uint256 amount)
        external
        override
    {
        require(msg.sender == contractManager, permissionError);
        IERC20(REFUND_TOKEN).transfer(beneficiary, amount);
    }

    function withdraw(address beneficiary)
        external
        override
    {
        require(msg.sender == contractManager, permissionError);
        uint256 amount = IERC20(REFUND_TOKEN).balanceOf(address(this));
        IERC20(REFUND_TOKEN).transfer(beneficiary, amount);
    }

    function updateManager(address account)
        external
        override
    {
        require(msg.sender == contractManager, permissionError);
        contractManager = account;
    }

    function getRefundAmount(address account)
        external
        override
        view
        returns(uint256)
    {
        return accountToRefund[account];
    }

    function receiveRefund()
        external
        override
    {
        require(accountToRefund[msg.sender] > 0, refundNotAvailable);
        IERC20(REFUND_TOKEN).transfer(msg.sender, accountToRefund[msg.sender]);
        accountToRefund[msg.sender] = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {

    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address _owner) external returns (uint256 balance);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEfforceWithDraw {

    /**
        @notice Withdraw funds from the smart contract to the beneficiary address.
        @dev Callable only by contract manager.
        @param beneficiary Account receiving the funds.
        @param amount The amount that will be withdrawn.
    */
    function withdraw(address beneficiary, uint256 amount) external;

    /**
        @notice Withdraw all the funds from the smart contract to the beneficiary address.
        @dev Callable only by contract manager.
        @param beneficiary Account receiving the funds.
    */
    function withdraw(address beneficiary) external;

    /**
        @notice Update the address of the contract manager.
        @dev Callable only bt contract manager.
        @param account New contract manager.
    */
    function updateManager(address account) external;

    /**
        @notice Get the amount that can be refunded by an account
        @param account The input account.
    */
    function getRefundAmount(address account) external view returns(uint256);

    /**
        @notice If the amount to be refund is greater than zero, the amount is transferred from the smart contract to the sender address.
    */
    function receiveRefund() external;
}