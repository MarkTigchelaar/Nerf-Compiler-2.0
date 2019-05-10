module stack;

class Stack(T) {
	struct stkNode(T) {
		T item;
		stkNode* next;
	}
	private stkNode!T* stks;
	private ulong size;

	public void push(T item) {
		stkNode!T* Nnode = new stkNode!T(item);
		Nnode.next = stks;
		stks = Nnode;
		size++;
	}

	public T pop() {
		if(size == 0) {
			return cast(T) null;
		}
		T value = stks.item;
		stks = stks.next;
		size--;
		return value;
	}

	public T peek() {
		if(stks is null) {
			return cast(T) null;
		}
		return stks.item;
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