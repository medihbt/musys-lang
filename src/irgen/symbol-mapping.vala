namespace Musys.IRGen {
    public class SymbolInfo {
        public enum Kind {
            NONE,
            GLOBL_CONST,  GLOBL_VAR, GLOBAL_FUNC,
            STATIC_CONST, LOCAL_VAR, FUNC_PARAM,
            RESERVED_CNT;
            public bool is_global() {
                return this == GLOBL_CONST || this == GLOBL_VAR || this == GLOBAL_FUNC;
            }
            public bool is_local_dynamic() {
                return this == LOCAL_VAR || this == FUNC_PARAM;
            }
        }
        public Kind             kind;
        public SymbolInfo?      parent;
        public Vala.Symbol      symbol;
        public Vala.Expression? init_expr;
        public Musys.Type       ir_type;
        public IR.Value         ir_value;
        public bool             is_signed;
    }
    public class SymbolMapper {
        internal Gee.TreeMap<Vala.Symbol, SymbolInfo> _info_map;
        internal unowned Generator                   _generator;

        public unowned SymbolInfo register_globl_constant(Vala.Constant constant) {
            string cname = get_symbol_cname(constant, _generator.vctx);
            assert_not_reached();
        }
        public unowned SymbolInfo register_globl_var(Vala.Field gvar) {
            assert_not_reached();
        }
        public unowned SymbolInfo register_local_constant(Vala.Constant lc) {
            assert_not_reached();
        }
        public unowned SymbolInfo register_local_var(Vala.Field lvar) {
            assert_not_reached();
        }

        public SymbolInfo? map_get_symbol(Vala.Symbol symbol) {
            if (_info_map.has_key(symbol))
                return _info_map.get(symbol);
            return null;
        }

        private IR.Constant _eval_get_result(Vala.Expression init_expr)
                            throws Error
        {
            if (_generator.rt == null)
                throw new RuntimeErr.NULL_PTR("parent generator has not started generating yet. rt is NULL!");
            unowned ExprGenerator exprgen = _generator.rt.expr_gen;
            exprgen.consteval_mode = true;
            IR.Value value = exprgen.generate(init_expr);
            return value as IR.Constant;
        }

        public SymbolMapper(Generator parent) {
            _generator = parent;
        }
    }

    public string get_symbol_cname(Vala.Symbol sym, Vala.CodeContext vctx)
    {
        string? attr_cname = sym.get_attribute_string("CCode", "cname", null);
        if (attr_cname != null)
            return attr_cname;
        if (sym.parent_node == vctx.root)
            return sym.name;
        return new Magler(sym, vctx).magle();
    }

    [Compact]
    internal class Magler {
        internal unowned Vala.Symbol      vsym;
        internal unowned Vala.CodeContext vctx;
        internal StringBuilder            name;
        internal uint                     cnt;
        internal unowned Vala.Namespace   root { get { return vctx.root; } }

        internal string magle()
        {
            bool imst = is_method_static();
            name.append(imst? "_ZZ": "_ZN");
            do_magle_append(vsym);
            if (!imst)
                name.append_c('E');
            return name.free_and_steal();
        }

        private void do_magle_append(Vala.Symbol curr)
        {
            if (curr == root)
                return;
            do_magle_append(curr.parent_symbol);
            name.append_printf("%d%s",
                                curr.name.length,
                                curr.name);
            if (curr != vsym && curr is Vala.Method)
                name.append_c('E');
        }

        internal Magler(Vala.Symbol vsym, Vala.CodeContext vctx) {
            this.vsym = vsym;
            this.vctx = vctx;
            this.name = new StringBuilder();
            this.cnt  = 0;
        }

        private bool is_method_static()
        {
            unowned Vala.Symbol curr = vsym;
            while (curr != root) {
                curr = curr.parent_symbol;
                if (curr is Vala.Method)
                    return true;
            }
            return false;
        }
    }
}
