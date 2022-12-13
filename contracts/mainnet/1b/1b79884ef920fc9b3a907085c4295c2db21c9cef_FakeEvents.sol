// SPDX-License-Identifier: UNLICENSED

contract FakeEvents {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public counter;

    function approval() public  {
        emit Approval(msg.sender, msg.sender, counter);
        counter++;
    }

}