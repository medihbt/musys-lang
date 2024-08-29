namespace Musys.IRGen {
    public class Generator: Vala.CodeVisitor {
        public IR.Module      module;
        public Vala.CodeContext vctx;
        public TypeContext  type_ctx {
            get { return module.type_ctx; }
        }
        internal Runtime rt;
        public override void visit_source_file(Vala.SourceFile source_file)
        {
            this.vctx     = source_file.context;
            rt            = new Runtime.temporary(this);
            rt.root       = vctx.root;
            rt.curr_scope = rt.root.scope;
            rt.root.accept(this);
            rt = null;
        }
        public override void visit_namespace(Vala.Namespace ns)
        {
            if (!ns.get_classes().is_empty)
                crash_node_nosupport("classes");
            if (!ns.get_delegates().is_empty)
                crash_node_nosupport("delegates");
            if (!ns.get_error_domains().is_empty)
                crash_node_nosupport("error domains");
            if (!ns.get_enums().is_empty)
                crash_node_nosupport("enums");
            if (!ns.get_interfaces().is_empty)
                crash_node_nosupport("interfaces");
            if (!ns.get_namespaces().is_empty)
                crash_node_nosupport("namespaces");
            foreach (var s in ns.get_structs())
                s.accept(this);
            foreach (var c in ns.get_constants())
                c.accept(this);
            foreach (var v in ns.get_fields())
                v.accept(this);
            foreach (var m in ns.get_methods())
                m.accept(this);
        }
        public override void visit_struct(Vala.Struct st)
        {
            if (st.external_package)
                return;
            if (st.is_simple_type())
                return;
            crash_unsupported(st);
        }
        public override void visit_constant(Vala.Constant c)
        {
            if (rt.curr_scope == rt.root.scope)
                rt.sym_map.register_globl_constant(c);
        }
        public override void visit_field(Vala.Field f)
        {
            var t = f.variable_type;
        }
        private IR.Value generate_expr(Vala.Expression expr, bool requires_constexpr = false) {
            assert_not_reached();
        }

        private static void crash_unsupported(Vala.CodeNode node) {
            crash(@"at SysY(Vala-based) source [$(node.source_reference)]:\n unsupported SysY source type $(node.type_name)");
        }
        private static void crash_node_nosupport(string node_name) {
            crash(@"SysY does not support $node_name\n");
        }

        [Compact]
        internal class Runtime {
            internal Generator      parent;
            internal ExprGenerator  expr_gen;
            internal TypeMapper     type_map;
            internal SymbolMapper   sym_map;
            internal Vala.Namespace root;
            internal Vala.Scope?    curr_scope;

            internal Runtime.temporary(Generator parent) {
                this.parent = parent;
                this.type_map = new TypeMapper.as_64bit(parent);
                this.expr_gen = new ExprGenerator();
                this.sym_map  = new SymbolMapper(parent);
                this.curr_scope = null;
                this.expr_gen.parent = parent;
            }
        }
    }
}