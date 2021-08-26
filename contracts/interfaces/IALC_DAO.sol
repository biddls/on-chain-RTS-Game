interface IALC_DAO {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function PAUSER_ROLE (  ) external view returns ( bytes32 );
  function balanceOf ( address account, uint256 id ) external view returns ( uint256 );
  function balanceOfBatch ( address[] accounts, uint256[] ids ) external view returns ( uint256[] );
  function burn ( address account, uint256 id, uint256 value ) external;
  function burnBatch ( address account, uint256[] ids, uint256[] values ) external;
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function getRoleMember ( bytes32 role, uint256 index ) external view returns ( address );
  function getRoleMemberCount ( bytes32 role ) external view returns ( uint256 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isApprovedForAll ( address account, address operator ) external view returns ( bool );
  function mint ( address to, uint256 id, uint256 amount, bytes data ) external;
  function mintBatch ( address to, uint256[] ids, uint256[] amounts, bytes data ) external;
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function safeBatchTransferFrom ( address from, address to, uint256[] ids, uint256[] amounts, bytes data ) external;
  function safeTransferFrom ( address from, address to, uint256 id, uint256 amount, bytes data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function unpause (  ) external;
  function uri ( uint256 ) external view returns ( string );
}
