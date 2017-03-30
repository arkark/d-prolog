module dprolog.util.UnionFind;

import std.stdio,
       std.conv,
       std.array,
       std.typecons,
       std.algorithm,
       std.functional;

class UnionFind(T, alias pred = (a, b) => 0) {

private:
    Node[T] storage;

public:
    this(Node[T] storage = null) {
        this.storage = storage;
    }

    void add(T value) {
        storage[value] = new Node(value);
    }

    void unite(T a, T b) {
        unite(storage[a], storage[b]);
    }

    bool same(T a, T b) {
        return same(storage[a], storage[b]);
    }

    T root(T value) {
        return find(storage[value]).value;
    }

    void clear() {
        storage = null;
    }

    auto opBinary(string op)(typeof(this) that) if (op == "~") {
        auto newUF = this.clone;
        foreach(k, v; that.storage) {
            newUF.storage[k] = v;
        }
        return newUF;
    }

    auto clone() {
        Node[T] newStorage = storage.dup;
        foreach(ref node; newStorage.byValue) {
            node = node.clone;
        }
        foreach(node; newStorage.byValue) {
            node.parent = node.parent is null ? null : newStorage[node.parent.value];
        }
        return new UnionFind(newStorage);
    }

    override string toString() {
        return "UnionFind(\n" ~
            storage.byKey.map!(
                k => "\t" ~ k.to!string ~ " => " ~ root(k).to!string
            ).join(",\n")
        ~ "\n)";
    }

private:
    void unite(Node x, Node y) {
        x = find(x);
        y = find(y);
        if (same(x, y)) return;

        if (pred(x.value, y.value)<0 || (pred(x.value, y.value)==0 && x.rank>y.rank)) {
            x.rank = max(x.rank, y.rank + 1);
            storage[y.value].parent = x;
        } else {
            y.rank = max(x.rank + 1, y.rank);
            storage[x.value].parent = y;
        }
    }

    bool same(Node x, Node y) {
        return find(x) == find(y);
    }

    Node find(Node node) {
        if (node.parent is null) {
            return node;
        } else {
            node.parent = find(node.parent);
            return node.parent;
        }
    }

    class Node {
        T value;
        int rank = 0;
        Node parent;

        this(T value, int rank = 0, Node parent = null) {
            this.value  = value;
            this.rank   = rank;
            this.parent = parent;
        }

        Node clone() {
            return new Node(value, rank, parent);
        }
    }
}


/* ---------- Unit Tests ---------- */

unittest {
    writeln(__FILE__, ": test");

    auto uf1 = new UnionFind!(int, (a, b) => a - b);

    assert(uf1.storage.length == 0);

    auto uf2 = uf1.clone;
    uf1.add(1); uf1.add(2); uf1.add(3);
    uf1.unite(1, 2);

    assert(uf1.storage.length == 3);
    assert(uf1.same(1, 2) && !uf1.same(2, 3) && !uf1.same(3, 1));

    assert(uf2.storage.length == 0);

    auto uf3 = uf1.clone;
    uf1.unite(2, 3);

    assert(uf1.storage.length == 3);
    assert(uf1.same(1, 2) && uf1.same(2, 3) && uf1.same(3, 1));

    assert(uf3.storage.length == 3);
    assert(uf3.same(1, 2) && !uf3.same(2, 3) && !uf3.same(3, 1));

    uf2.add(0);
    auto uf4 = uf1 ~ uf2;

    assert(uf1.storage.length == 3);
    assert(uf1.same(1, 2) && uf1.same(2, 3) && uf1.same(3, 1));

    assert(uf4.storage.length == 4);
    assert(uf4.same(1, 2) && uf4.same(2, 3) && uf4.same(3, 1) && !uf4.same(0, 1) && !uf4.same(0, 2) && !uf4.same(0, 3));

    uf4.unite(0, 1);

    assert(uf1.storage.length == 3);
    assert(uf1.same(1, 2) && uf1.same(2, 3) && uf1.same(3, 1));

    assert(uf4.storage.length == 4);
    assert(uf4.same(1, 2) && uf4.same(2, 3) && uf4.same(3, 1) && uf4.same(0, 1) && uf4.same(0, 2) && uf4.same(0, 3));
}
