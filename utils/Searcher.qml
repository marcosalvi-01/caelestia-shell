import "scripts/fzf.js" as Fzf
import "scripts/fuzzysort.js" as Fuzzy
import QtQuick
import Quickshell

Singleton {
    required property list<QtObject> list
    property string key: "name"
    property bool useFuzzy: false
    property var extraOpts: ({})

    // Extra stuff for fuzzy
    property list<string> keys: [key]
    property list<real> weights: [1]

    readonly property var fzf: useFuzzy ? [] : new Fzf.Finder(list, Object.assign({
        selector
    }, extraOpts))
    readonly property list<var> fuzzyPrepped: useFuzzy ? list.map(e => {
        const obj = {
            _item: e
        };
        for (const k of keys)
            obj[k] = Fuzzy.prepare(e[k]);
        return obj;
    }) : []

    function transformSearch(search: string): string {
        return search;
    }

    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }

    function queryWithMetadata(search: string): list<var> {
        search = transformSearch(search);
        if (!search)
            return [...list].map(item => ({
                        item,
                        score: 0
                    }));

        if (useFuzzy) {
            const options = Object.assign({
                all: true,
                keys,
                scoreFn: r => weights.reduce((a, w, i) => a + r[i].score * w, 0)
            }, extraOpts);

            return Fuzzy.go(search, fuzzyPrepped, options).map(r => ({
                        item: r.obj._item,
                        score: options.scoreFn(r)
                    }));
        }

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        }).map(r => ({
                    item: r.item,
                    score: r.score
                }));
    }

    function query(search: string): list<var> {
        return queryWithMetadata(search).map(r => r.item);
    }
}
