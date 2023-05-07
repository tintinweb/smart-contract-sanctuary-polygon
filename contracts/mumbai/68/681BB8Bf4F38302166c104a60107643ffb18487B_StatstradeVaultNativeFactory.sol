/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract StatstradeVaultNativeFactory {
  enum VaultStatus { Undefined, Active, ActiveAuto, Arbitration }
  
  enum VaultAccountStatus { Undefined, Requested, Active, Locked }
  
  enum VaultRequestStatus { Undefined, Pending, Confirmed, RejectedSite, Rejected, Approved }
  
  address public g__SiteAuthority;
  
  mapping(address => bool) public g__SiteSupport;
  
  uint16 public g__SiteArbitrationThreshold;
  
  struct WithdrawRequest{
    uint amount;
    VaultRequestStatus status;
  }
  
  struct Vault{
    VaultStatus status;
    string name;
    address owner;
    uint total_pool;
    uint total_requested;
    uint16 total_players;
    uint16 total_arbitration;
    uint16 vault_tax_rate;
    uint vault_tax_max;
    uint vault_withdraw_min;
    uint vault_withdraw_max;
  }
  
  struct VaultAccount{
    VaultAccountStatus status;
    bool arbitration;
    string last_withdraw_id;
    uint last_withdraw_time;
  }
  
  event VaultEvent(string event_type,string event_id,address sender,uint value);
  
  uint16 public g__VaultCount;
  
  mapping(string => Vault) public g__VaultLookup;
  
  mapping(string => mapping(address => VaultAccount)) public g__VaultAccounts;
  
  mapping(
    string => mapping(address => mapping(string => WithdrawRequest))
  ) public g__VaultWithdrawals;
  
  constructor(uint16 site_arbitration_threshold) {
    g__SiteAuthority = msg.sender;
    g__SiteArbitrationThreshold = site_arbitration_threshold;
  }
  
  function ut__assert_admin(address user_address) internal view {
    require(
      (user_address == g__SiteAuthority) || g__SiteSupport[user_address],
      "Site admin only."
    );
  }
  
  function ut__assert_owner(string memory vault_id,address user_address) internal view {
    require(
      g__VaultLookup[vault_id].owner == user_address,
      "Vault owner only."
    );
    require(
      g__VaultLookup[vault_id].status != VaultStatus.Arbitration,
      "Vault in arbitration."
    );
  }
  
  function ut__assert_management(string memory vault_id,address user_address) internal view {
    require(
      (g__VaultLookup[vault_id].owner == user_address) || (user_address == g__SiteAuthority) || g__SiteSupport[user_address],
      "Vault management only."
    );
  }
  
  function ut__get_account(string memory vault_id,address user_address) internal view returns(VaultAccount memory) {
    VaultAccount memory account = g__VaultAccounts[vault_id][user_address];
    require(
      account.status != VaultAccountStatus.Undefined,
      "User not found."
    );
    return account;
  }
  
  function ut__get_withdraw(string memory vault_id,address user_address,string memory withdraw_id) internal view returns(WithdrawRequest memory) {
    WithdrawRequest memory request = g__VaultWithdrawals[vault_id][user_address][withdraw_id];
    require(
      request.status != VaultRequestStatus.Undefined,
      "Request not found."
    );
    return request;
  }
  
  function site__change_authority(address new_authority) external {
    require(msg.sender == g__SiteAuthority,"Site authority only.");
    g__SiteAuthority = new_authority;
  }
  
  function site__add_support(address user) external {
    require(msg.sender == g__SiteAuthority,"Site authority only.");
    g__SiteSupport[user] = true;
  }
  
  function site__remove_support(address user) external {
    ut__assert_admin(msg.sender);
    delete g__SiteSupport[user];
  }
  
  function site__vault_create(string memory vault_id,string memory name,address owner,uint16 vault_tax_rate,uint vault_tax_max,uint vault_withdraw_min,uint vault_withdraw_max) external {
    ut__assert_admin(msg.sender);
    require(
      VaultStatus.Undefined == g__VaultLookup[vault_id].status,
      "Vault already exists."
    );
    Vault memory vault = Vault({
      total_requested: 0,
      vault_withdraw_max: vault_withdraw_max,
      total_pool: 0,
      name: name,
      total_arbitration: 0,
      status: VaultStatus.Active,
      vault_withdraw_min: vault_withdraw_min,
      vault_tax_rate: vault_tax_rate,
      vault_tax_max: vault_tax_max,
      owner: owner,
      total_players: 0
    });
    ++g__VaultCount;
    g__VaultLookup[vault_id] = vault;
    emit VaultEvent("vault_create",vault_id,owner,0);
  }
  
  function site__account_open(string memory vault_id,address user_address) external {
    ut__assert_admin(msg.sender);
    require(
      (g__VaultLookup[vault_id].status == VaultStatus.Active) || (g__VaultLookup[vault_id].status == VaultStatus.ActiveAuto),
      "Vault incorrect status"
    );
    require(
      g__VaultAccounts[vault_id][user_address].status == VaultAccountStatus.Undefined,
      "Account already registered."
    );
    VaultAccount memory account = VaultAccount(VaultAccountStatus.Requested,false,"",0);
    uint16 total_players = ++g__VaultLookup[vault_id].total_players;
    g__VaultAccounts[vault_id][user_address] = account;
    emit VaultEvent("account_open",vault_id,user_address,total_players);
  }
  
  function site__account_close(string memory vault_id,address user_address) external {
    ut__assert_admin(msg.sender);
    VaultAccount memory account = ut__get_account(vault_id,user_address);
    require(
      account.status == VaultAccountStatus.Active,
      "Account incorrect status."
    );
    delete g__VaultAccounts[vault_id][user_address];
    uint16 total_players = --g__VaultLookup[vault_id].total_players;
    emit VaultEvent("account_close",vault_id,user_address,total_players);
  }
  
  function owner__set_auto(string memory vault_id,bool is_auto) external {
    ut__assert_owner(vault_id,msg.sender);
    g__VaultLookup[vault_id].status = (is_auto ? VaultStatus.ActiveAuto : VaultStatus.Active);
  }
  
  function owner__account_open_confirm(string memory vault_id,address user_address) external {
    ut__assert_owner(vault_id,msg.sender);
    VaultAccount memory account = ut__get_account(vault_id,user_address);
    require(
      account.status == VaultAccountStatus.Requested,
      "Account incorrect status."
    );
    g__VaultAccounts[vault_id][user_address].status = VaultAccountStatus.Active;
    emit VaultEvent("account_open_confirm",vault_id,user_address,0);
  }
  
  function owner__account_lock(string memory vault_id,address user_address) external {
    ut__assert_management(vault_id,msg.sender);
    VaultAccount memory account = ut__get_account(vault_id,user_address);
    require(
      account.status == VaultAccountStatus.Active,
      "Account incorrect status."
    );
    g__VaultAccounts[vault_id][user_address].status = VaultAccountStatus.Locked;
    emit VaultEvent("account_lock",vault_id,user_address,0);
  }
  
  function owner__account_unlock(string memory vault_id,address user_address) external {
    ut__assert_owner(vault_id,msg.sender);
    VaultAccount memory account = ut__get_account(vault_id,user_address);
    require(
      account.status == VaultAccountStatus.Locked,
      "Account not banned."
    );
    g__VaultAccounts[vault_id][user_address].status = VaultAccountStatus.Active;
    emit VaultEvent("account_unlock",vault_id,user_address,0);
  }
  
  function user__arbitration_vote(string memory vault_id) external {
    VaultAccount memory account = ut__get_account(vault_id,msg.sender);
    require(!account.arbitration,"Account arbitration voted.");
    g__VaultAccounts[vault_id][msg.sender].arbitration = true;
    uint16 total_arbitration = ++g__VaultLookup[vault_id].total_arbitration;
    uint16 total_players = g__VaultLookup[vault_id].total_players;
    if((total_arbitration > 4) && (total_arbitration > ((g__SiteArbitrationThreshold * total_players) / 100))){
      g__VaultLookup[vault_id].status = VaultStatus.Arbitration;
    }
    emit VaultEvent("arbitration_vote",vault_id,msg.sender,total_arbitration);
  }
  
  function user__arbitration_unvote(string memory vault_id) external {
    require(
      g__VaultLookup[vault_id].status != VaultStatus.Arbitration,
      "Vault in arbitration."
    );
    VaultAccount memory account = ut__get_account(vault_id,msg.sender);
    require(account.arbitration,"Account not voted.");
    delete g__VaultAccounts[vault_id][msg.sender].arbitration;
    uint16 total_arbitration = --g__VaultLookup[vault_id].total_arbitration;
    emit VaultEvent("arbitration_unvote",vault_id,msg.sender,total_arbitration);
  }
  
  function user__withdraw_request(string memory vault_id,string memory withdraw_id,uint amount) external {
    VaultAccount memory account = g__VaultAccounts[vault_id][msg.sender];
    Vault memory vault = g__VaultLookup[vault_id];
    require(
      (account.status == VaultAccountStatus.Active) || (vault.status == VaultStatus.Arbitration),
      "Withdraw not allowed."
    );
    require(
      g__VaultWithdrawals[vault_id][msg.sender][withdraw_id].status == VaultRequestStatus.Undefined,
      "Withdraw already requested."
    );
    require(
      amount >= vault.vault_withdraw_min,
      "Withdraw amount below minimum."
    );
    require(
      amount <= vault.vault_withdraw_max,
      "Withdraw amount above maximum"
    );
    uint new_total_requested = (g__VaultLookup[vault_id].total_requested + amount);
    require(
      g__VaultLookup[vault_id].total_pool >= new_total_requested,
      "Withdraw over pool limit."
    );
    g__VaultWithdrawals[vault_id][msg.sender][withdraw_id] = WithdrawRequest(amount,VaultRequestStatus.Pending);
    g__VaultLookup[vault_id].total_requested = new_total_requested;
    emit VaultEvent("withdraw_request",withdraw_id,msg.sender,amount);
  }
  
  function site__withdraw_confirm(string memory vault_id,address user_address,string memory withdraw_id,uint amount) external {
    ut__assert_admin(msg.sender);
    WithdrawRequest memory request = ut__get_withdraw(vault_id,user_address,withdraw_id);
    require(
      request.status == VaultRequestStatus.Pending,
      "Withdraw not pending"
    );
    require(request.amount == amount,"Withdraw amount incorrect");
    g__VaultWithdrawals[vault_id][user_address][withdraw_id].status = VaultRequestStatus.Confirmed;
    emit VaultEvent("withdraw_confirm_site",withdraw_id,user_address,amount);
  }
  
  function site__withdraw_reject(string memory vault_id,address user_address,string memory withdraw_id) external {
    ut__assert_admin(msg.sender);
    WithdrawRequest memory request = ut__get_withdraw(vault_id,user_address,withdraw_id);
    require(
      request.status == VaultRequestStatus.Pending,
      "Withdraw not pending"
    );
    g__VaultWithdrawals[vault_id][user_address][withdraw_id].status = VaultRequestStatus.RejectedSite;
    g__VaultLookup[vault_id].total_requested -= request.amount;
    emit VaultEvent("withdraw_reject_site",withdraw_id,user_address,request.amount);
  }
  
  function ut__withdraw_transfer(string memory vault_id,address user_address,string memory withdraw_id,WithdrawRequest memory request,bool arbitrated) internal {
    uint vault_tax = ((request.amount * g__VaultLookup[vault_id].vault_tax_rate) / 10000);
    if(vault_tax > g__VaultLookup[vault_id].vault_tax_max){
      vault_tax = g__VaultLookup[vault_id].vault_tax_max;
    }
    if(arbitrated){
      payable(g__SiteAuthority).transfer(vault_tax);
    }
    else{
      payable(g__VaultLookup[vault_id].owner).transfer(vault_tax);
    }
    payable(user_address).transfer(request.amount - vault_tax);
    g__VaultWithdrawals[vault_id][user_address][withdraw_id].status = VaultRequestStatus.Approved;
    g__VaultLookup[vault_id].total_pool -= request.amount;
    g__VaultLookup[vault_id].total_requested -= request.amount;
    emit VaultEvent("withdraw_transfer",withdraw_id,user_address,request.amount);
  }
  
  function owner__withdraw_approve(string memory vault_id,address user_address,string memory withdraw_id,uint amount) external {
    ut__assert_owner(vault_id,msg.sender);
    WithdrawRequest memory request = g__VaultWithdrawals[vault_id][user_address][withdraw_id];
    require(
      request.status == VaultRequestStatus.Confirmed,
      "Withdraw not confirmed"
    );
    require(request.amount == amount,"Withdraw amount incorrect");
    ut__withdraw_transfer(vault_id,user_address,withdraw_id,request,false);
  }
  
  function owner__withdraw_reject(string memory vault_id,address user_address,string memory withdraw_id) external {
    ut__assert_owner(vault_id,msg.sender);
    WithdrawRequest memory request = g__VaultWithdrawals[vault_id][user_address][withdraw_id];
    require(
      request.status == VaultRequestStatus.Confirmed,
      "Withdraw not confirmed"
    );
    g__VaultWithdrawals[vault_id][user_address][withdraw_id].status = VaultRequestStatus.Rejected;
    g__VaultLookup[vault_id].total_requested -= request.amount;
    emit VaultEvent("withdraw_reject",withdraw_id,user_address,request.amount);
  }
  
  function user__withdraw_self(string memory vault_id,string memory withdraw_id) external {
    require(
      (g__VaultLookup[vault_id].status != VaultStatus.Active),
      "No self service."
    );
    WithdrawRequest memory request = g__VaultWithdrawals[vault_id][msg.sender][withdraw_id];
    require(
      request.status == VaultRequestStatus.Confirmed,
      "Withdraw not confirmed"
    );
    ut__withdraw_transfer(vault_id,msg.sender,withdraw_id,request,true);
  }
  
  function user__account_deposit(string memory vault_id) external payable {
    VaultAccount memory account = ut__get_account(vault_id,msg.sender);
    require(
      account.status == VaultAccountStatus.Active,
      "Account not active."
    );
    g__VaultLookup[vault_id].total_pool += msg.value;
    emit VaultEvent("account_deposit",vault_id,msg.sender,msg.value);
  }
}