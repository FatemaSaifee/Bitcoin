defmodule Network do
  use GenServer
  def generateNetwork do
    networkId = startNetwork()
    networkId
  end

  @doc """

  ## Block Structue
    blockchain:   List of block IDs - blockchain
    transactions: List of unconfirmed transactions in the transaction pool
    walletIdPublicKeysMap:  Map of all wallet ids and their public keys in the network
  """
  def init(:ok) do
    timeStamp = :os.system_time(:millisecond)
    {:ok, {[], [], []}} 
  end
  def startNetwork do
    {:ok,pid}=GenServer.start_link(__MODULE__, :ok,[])
    pid
  end

  def handle_call({:GetNetworkBlockchain}, _from ,state) do
    {a,b,c} = state
    {:reply, a, state}
  end
  def getNetworkBlockchain(pid) do
    GenServer.call(pid,{:GetNetworkBlockchain})
  end


  def handle_call({:GetNetworkTransactionPool}, _from ,state) do
    {a,b,c} = state
    {:reply, b, state}
  end
  def getNetworkTransactionPool(pid) do
    GenServer.call(pid,{:GetNetworkTransactionPool})
  end

  def updateNetworkTransactionPool(pid,transaction) do
    GenServer.call(pid, {:UpdateNetworkTransactionPool,transaction})
  end
  def handle_call({:UpdateNetworkTransactionPool,transaction}, _from ,state) do
    {a,b,c} = state
    state={a, b ++ [transaction],c}
    {:reply,b,state}
  end

  def removeTransactionFromPool(pid, transactions) do
    GenServer.call(pid, {:RemoveTransactionFromPool,transactions})
  end
  def handle_call({:RemoveTransactionFromPool, transactions}, _from ,state) do
    {a,b,c} = state
    state={a, b -- transactions,c}
    {:reply,b,state}
  end

  def updateNetworkBlockchain(pid,blockchain) do
    GenServer.call(pid, {:UpdateNetworkBlockchain,blockchain})
  end
  def handle_call({:UpdateNetworkBlockchain,blockchain}, _from ,state) do
    {a,b,c} = state
    state={blockchain,b,c}
    {:reply,a,state}
  end

  def updateNetworkWalletIdMaps(pid,map) do
    GenServer.call(pid, {:UpdateNetworkWalletIdMaps,map})
  end
  def handle_call({:UpdateNetworkWalletIdMaps,map}, _from ,state) do
    {a,b,c} = state
    state={a,b,c++[map]}
    {:reply,c,state}
  end

end


# Topologies.main()
# Topologies.waitIndefinitely()