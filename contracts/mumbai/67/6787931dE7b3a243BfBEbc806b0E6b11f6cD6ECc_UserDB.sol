/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract UserDB {
    
    struct  Transaction {
        uint transaction_id;
        string from_wallet;
        uint to_user;
        string to_wallet;
        uint from_user;
        string txn;
        string amount_in_token;
        string date;
        string transfer_reason;
        string token;
    }
    struct Request {
        uint request_id;
        bool is_paied;
        uint sender_id; // the one that create this request
        uint recipient_id;  // the one that get asked to pay and need to pay 
        string date;
        string token;
        string amount_in_token;
        string request_reason;
        string level_of_urgency;
    }


    struct User {
        uint user_id;
        string name;
        string profile_pic;
        string phone_number;
        string erc20_wallet_address; 
        string[] erc20_wallets;
        uint[] friend_list;
        uint[] transaction_ids ;
        uint transaction_count_for_user;
        mapping (uint => Transaction)  transaction_history;
        uint[] request_ids ;
        uint request_count_for_user;
        mapping(uint => Request) requests;
        string[] privateKeys;
        string mainPrivateKey;
    }
    mapping(uint => User) private users;
    uint public userCount;
    uint public transaction_count;
    uint public request_count;
    event IsPaiedChanged(uint indexed user_id, uint indexed request_id, bool is_paied);

    /**
        User related functions here :
    **/
    function addUser(string memory name ,string memory profile_pic , string memory phone_number , string memory erc20_wallet_address) public {
        users[userCount].user_id = userCount;
        users[userCount].name = name;
        users[userCount].transaction_count_for_user = 0;
        users[userCount].request_count_for_user = 0;
        users[userCount].profile_pic = profile_pic;
        users[userCount].phone_number = phone_number;
        users[userCount].erc20_wallet_address = erc20_wallet_address;
        add_erc20_wallet(users[userCount].user_id , erc20_wallet_address);

        userCount++;
    }





    function addMultipleUsers(string[]memory name ,string[] memory profile_pic , string[] memory phone_number , string []memory erc20_wallet_address ) public{
        for(uint i = 0 ; i< name.length;i++)
        {
            users[userCount].user_id = userCount;
        users[userCount].name = name[i];
        users[userCount].transaction_count_for_user = 0;
        users[userCount].request_count_for_user = 0;
        users[userCount].profile_pic = profile_pic[i];
        users[userCount].phone_number = phone_number[i];
        users[userCount].erc20_wallet_address = erc20_wallet_address[i];
        add_erc20_wallet(users[userCount].user_id , erc20_wallet_address[i]);

        userCount++;
        }
    }
    /// privete keys

    function add_private_key(uint user_id, string memory private_key) public {
    users[user_id].privateKeys.push(private_key);
}
function remove_private_key(uint user_id, uint key_index) public {
    require(key_index < users[user_id].privateKeys.length, "Invalid key index");
    users[user_id].privateKeys[key_index] = users[user_id].privateKeys[users[user_id].privateKeys.length - 1];
    users[user_id].privateKeys.pop();
}
function getPrivateKeys(uint user_id) public view returns (string[] memory) {
    return users[user_id].privateKeys;
}
function changeMainPrivateKey(uint user_id, string memory new_private_key) public {
    users[user_id].mainPrivateKey = new_private_key;
}

function getMainPrivateKey(uint user_id) public view returns(string memory) {
    return users[user_id].mainPrivateKey;
}




    function changeNameOfUser (uint user_id , string memory new_value) public
    {
        users[user_id].name = new_value;
    }

    function changeProfilePic (uint user_id , string memory new_value) public
    {
        users[user_id].profile_pic = new_value;
    }

    function changeErc20Wallet (uint user_id , string memory new_value) public
    {
        users[user_id].erc20_wallet_address = new_value;
    }


    function getNameOfUser(uint user_id) public view returns ( string memory)
    {
         return (users[user_id].name);
    }

    function getProfilePic(uint user_id) public view returns ( string memory)
    {
         return (users[user_id].profile_pic);
    }

    function getPhoneNumber(uint user_id) public view returns ( string memory)
    {
         return (users[user_id].phone_number);
    }

    function getErc20WalletAddress(uint user_id) public view returns ( string memory)
    {
         return (users[user_id].erc20_wallet_address);
    }
    function get_erc20_wallets(uint user_id) public view returns (string[] memory) {
    return users[user_id].erc20_wallets;
}


    function getFriendList(uint user_id) public view returns ( uint[] memory)
    {
         return (users[user_id].friend_list);
    }

    function getTransactionCount(uint user_id) public view returns ( uint)
    {
         return (users[user_id].transaction_count_for_user);
    }

    function getRequestCount(uint user_id) public view returns ( uint)
    {
         return (users[user_id].request_count_for_user);
    }

    function getRequestIds(uint user_id) public view returns ( uint[] memory)
    {
         return (users[user_id].request_ids);
    }
    
    function getTransactionIds(uint user_id) public view returns ( uint[] memory)
    {
         return (users[user_id].transaction_ids);
    }
    
    function add_erc20_wallet(uint user_id, string memory wallet_address) public {
    users[user_id].erc20_wallets.push(wallet_address);
}
function remove_erc20_wallet(uint user_id, uint wallet_index) public {
    require(wallet_index < users[user_id].erc20_wallets.length, "Invalid wallet index");
    users[user_id].erc20_wallets[wallet_index] = users[user_id].erc20_wallets[users[user_id].erc20_wallets.length - 1];
    users[user_id].erc20_wallets.pop();
}






    /**
        Friend related functions here :
    **/

    function addFriend(uint user_id, uint friend_user_id) public{
        // Add friend to user's friend listA
        users[user_id].friend_list.push(friend_user_id);
    }
    
    function deleteFriend(uint user_id, uint friend_user_id) public {
    // Find the index of the friend in the friend_list
    uint friendIndex;
    for (uint i = 0; i < users[user_id].friend_list.length; i++) {
        if (users[user_id].friend_list[i] == friend_user_id) {
            friendIndex = i;
            break;
        }
    }
    // Remove the friend from the friend_list
    uint[] memory newFriendList = new uint[](users[user_id].friend_list.length - 1);
    for (uint i = 0; i < friendIndex; i++) {
        newFriendList[i] = users[user_id].friend_list[i];
    }
    for (uint i = friendIndex; i < newFriendList.length; i++) {
        newFriendList[i] = users[user_id].friend_list[i + 1];
    }
    users[user_id].friend_list = newFriendList;
} 
    

    /**
        requests related functions here :
    **/
    function addRequest(uint user_id,uint recipient_id, string memory date, string memory token, string memory amount_in_token, string memory request_reason , string memory level_of_urgency) public {
        uint request_count_user = users[user_id].request_count_for_user;
        uint request_count_recipient = users[recipient_id].request_count_for_user;
        users[user_id].requests[request_count_user] = Request(request_count, false, user_id ,recipient_id,date,token,amount_in_token,request_reason,level_of_urgency);
        users[recipient_id].requests[request_count_recipient] = Request(request_count, false, user_id ,recipient_id,date,token,amount_in_token,request_reason,level_of_urgency);
    
        users[user_id].request_ids.push(request_count);
        users[recipient_id].request_ids.push(request_count);
        
        request_count++;

        users[user_id].request_count_for_user++;
        users[recipient_id].request_count_for_user++;

    }

     function changeIsPaied(uint user_id, uint request_id) public {
    uint recipient_id = users[user_id].requests[request_id].recipient_id;
    bool current_value = users[user_id].requests[request_id].is_paied;
    users[user_id].requests[request_id].is_paied = !current_value;
    users[recipient_id].requests[request_id].is_paied = !current_value;

    emit IsPaiedChanged(user_id, request_id, !current_value);
    emit IsPaiedChanged(recipient_id, request_id, !current_value);
}



     function changeToken (uint user_id , uint request_id , string memory new_token) public
    {
        uint recipientId = users[user_id].requests[request_id].recipient_id ;
        users[user_id].requests[request_id].token = new_token;
        users[recipientId].requests[request_id].token = new_token;
    }




    function getRequest(uint user_id, uint request_id) public view returns(Request memory) {
        return users[user_id].requests[request_id];
    }
    
    function request_getIsPaid(uint user_id, uint request_id) public view returns(bool) {
        return users[user_id].requests[request_id].is_paied;
    }

    function request_getSenderId(uint user_id, uint request_id) public view returns(uint) {
        return users[user_id].requests[request_id].sender_id;
    }

    function request_getRecipientId(uint user_id, uint request_id) public view returns(uint) {
        return users[user_id].requests[request_id].recipient_id;
    }

    function request_amountInToken(uint user_id, uint request_id) public view returns(string memory) {
        return users[user_id].requests[request_id].amount_in_token;
    }

    function request_getDate(uint user_id, uint request_id) public view returns(string memory) {
        return users[user_id].requests[request_id].date;
    }

    function request_getToken(uint user_id, uint request_id) public view returns(string memory) {
        return users[user_id].requests[request_id].token;
    }

    function request_requestReason(uint user_id, uint request_id) public view returns(string memory) {
        return users[user_id].requests[request_id].request_reason;
    }

    /**
        Transaction related functions here :
    **/
    function addTransaction(uint user_id, string memory from_wallet, uint to_user, string memory to_wallet, string memory txn, string memory amount_in_token, string memory date, string memory transfer_reason , string memory token) public {
        
        uint transaction_count_user = users[user_id].transaction_count_for_user;
        uint transaction_count_recipient = users[to_user].transaction_count_for_user;
        users[user_id].transaction_history[transaction_count_user] = Transaction(transaction_count, from_wallet, to_user, to_wallet, user_id, txn, amount_in_token, date, transfer_reason, token);
        users[to_user].transaction_history[transaction_count_recipient] =Transaction(transaction_count, from_wallet, to_user, to_wallet, user_id, txn, amount_in_token, date, transfer_reason, token);
        users[user_id].transaction_ids.push(transaction_count);
        users[to_user].transaction_ids.push(transaction_count);
        transaction_count++;
        users[user_id].transaction_count_for_user++;
        users[to_user].transaction_count_for_user++;
        
        
    
    }

    function getTransactionHistory(uint user_id, uint transaction_id) public view returns(Transaction memory) {
        return users[user_id].transaction_history[transaction_id];
    }

    function transaction_getFromWallet(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].from_wallet);
    }


    function transaction_getDate(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].date);
    }


    function transaction_getTransfer_reason(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].transfer_reason);
    }

    function transaction_getToken(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].token);
    }

    function transaction_getTxn(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].txn);
    }

    function transaction_getToUser(uint user_id, uint transaction_id) public view returns ( uint)
    {
         return (users[user_id].transaction_history[transaction_id].to_user);
    }

    function transaction_getToWallet(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].to_wallet);
    }

    function transaction_getFromUser(uint user_id, uint transaction_id) public view returns ( uint)
    {
         return (users[user_id].transaction_history[transaction_id].from_user);
    }

    function transaction_getAmountInToken(uint user_id, uint transaction_id) public view returns ( string memory)
    {
         return (users[user_id].transaction_history[transaction_id].amount_in_token);
    }


    
}