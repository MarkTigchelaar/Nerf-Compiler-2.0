module stack;


class Stack {
	struct stkNode {
		string str;
		stkNode* next;
	}

	private stkNode* stks;
	private ulong size;

	this() {
		stks = null;
	}

	public void push(string str) {
		stkNode* Nnode = new stkNode(str);
		Nnode.next = stks;
		stks = Nnode;
		size++;
	}

	public string pop() {
		if(size == 0) { return ""; }
		string sh = stks.str;
		stks = stks.next;
		size--;
		return sh;
	}

	public string peek() {
		if(stks is null) {
			return "";
		}
		return stks.str;
	}

	public ulong getSize() {
		return size;
	}

	public bool isEmpty() {
		return getSize() < 1;
	}

	public void clear() {
		stks = null;
		size = 0;
	}

}