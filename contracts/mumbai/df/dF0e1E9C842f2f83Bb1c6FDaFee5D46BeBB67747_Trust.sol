// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

error SEND_MORE_FUNDS();
error TRANSFER_FAILED();
error ONLY_ONWER_CAN_CALL_FUNCTION();
error JOB_NOT_DONE();
error JOB_DONE();
error STILL_HAVE_TIME();

contract Trust {
    // address of owner
    address public immutable owner;

    // percentage of profit he/she is willing to give
    uint256 public immutable percentage;

    // number of gigs owner will give commionsion/cut to bielevers
    uint256 public immutable gigCount;

    // Arrays of supporters/Believers
    address[] public believers;

    // count of projects done
    uint256 public projectCount;

    // address of the trustFactory contract
    address payable public platformAddress;

    // contract creation time
    uint256 public contractCreationTime;


    constructor(uint256 _percentage, address _owner, uint256 _gigCount, address _platformAddress) {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(_owner);
        percentage = _percentage;
        gigCount = _gigCount;
        platformAddress = payable(_platformAddress);

        contractCreationTime = block.timestamp;
    }

    // adding senior / Believer to the believers array
    function AddBeliever() payable public {
        if(msg.value < 1e17){ // 1,00,000,000,000,000,000 = 1e17 = 1 * 10 * 17 = 0.1 Eth
            revert SEND_MORE_FUNDS();
        }
        believers.push(msg.sender);
    }

    // give money to believers and owner
    function gettingPaid(uint256 _amount) payable public{
        if(_amount < 1e14 || msg.value < _amount)  { // 1,00,000,000,000,000 = 1e14 = 1 * 10 ** 14 =  0.0001 ETH 
            revert SEND_MORE_FUNDS();
        }  
        projectCount++;
        // sending money to believers
        uint256 believersAmount = (msg.value * percentage) / 100;
        if(believers.length >= 1){
        for(uint256 i=0; i < believers.length; i++){
            (bool success, ) = believers[i].call{value: believersAmount / believers.length }("");
            // require(success, "Transfer failed");
            if(!success){
                revert TRANSFER_FAILED();
            }
        }
    }
        // sending money to contract owner
        (bool success1, ) = owner.call{value: msg.value - believersAmount }("");
         if(!success1){
                revert TRANSFER_FAILED();
            }
    }

    // function to free owner from paying cut to bieleivers
    function freeOwner() public {
        if(msg.sender != owner){
            revert ONLY_ONWER_CAN_CALL_FUNCTION();
        }
        if(projectCount < gigCount){
            revert JOB_NOT_DONE();
        }
        
        // send stake money back to believers
        if(believers.length >= 1){
        for(uint256 i=0; i < believers.length; i++){
            (bool success, ) = believers[i].call{value: 1e17 / believers.length }(""); // 0.1 Ether
            if(!success){
                revert TRANSFER_FAILED();
            }
        }
        }

        // empty the array
        delete believers;
    }

    // function to get money to platform if the owner cannot able to perform and get gis and complete them
    function platformGettingPaid() public {
        if(projectCount > gigCount){
            revert JOB_DONE();
        }
        // testing
        if(block.timestamp < contractCreationTime + 10 seconds){
            revert STILL_HAVE_TIME();
        }
        // production
        // if(block.timestamp < contractCreationTime + 12 weeks){
        //     revert STILL_HAVE_TIME();
        // }
        (bool success1, ) = platformAddress.call{value: address(this).balance }("");
         if(!success1){
                revert TRANSFER_FAILED();
            }

    }

    // get the balance 
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    // get the length of array
    function noOfBelievers() public view returns(uint256){
        return believers.length;
    }

    // get the balance of owner
    function getOwnerBalance() public view returns(uint256){
        return owner.balance;
    }

    // get the balance of 1st beliver
    function getBeliverBalance() public view returns(uint256){
        return believers[0].balance;
    }

    // Function to receive Ether. msg.data must be empty
      receive() external payable {}

    // Fallback function is called when msg.data is not empty
      fallback() external payable {}

    // withdraw the extra fund from smart contract to trust Factory contract
    function withdraw() public {
        if(block.timestamp < contractCreationTime + 10 seconds){
            revert STILL_HAVE_TIME();
        }

        (bool success, ) = platformAddress.call{value: address(this).balance }("");
         if(!success){
                revert TRANSFER_FAILED();
            }
    }

}