namespace Musys.IRGen {
    public int int_type_get_rank(Vala.IntegerType vity)
    {
        var type_sym = static_cast<Vala.Struct>(vity.type_symbol);
        if (unlikely(type_sym == null)) {
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                      "encountered IntegerType %s without symbol\n",
                      vity.to_qualified_string());
        }
        return type_sym.rank;
    }
    public int float_type_get_rank(Vala.FloatingType vfty)
    {
        var type_sym = static_cast<Vala.Struct>(vfty.type_symbol);
        if (unlikely(type_sym == null)) {
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                      "encountered FloatingType %s without symbol\n",
                      vfty.to_qualified_string());
        }
        return type_sym.rank;
    }

    public class TypeMapper {
        public  unowned Generator   parent  {get; set;}
        public  unowned TypeContext type_ctx{get; private set;}
        private IntType _vintty_rank_map[12];
        private bool _vintty_rank_signed[12];
        public  uint word_size{
            get { return type_ctx.machine_word_size; }
        }

        public IntTypeInfo map_int_type(Vala.IntegerType ity)
        {
            var rank = int_type_get_rank(ity);
            return IntTypeInfo() {
                int_ty    = _vintty_rank_map[rank],
                is_signed = _vintty_rank_signed[rank]
            };
        }
        public FloatType map_float_type(Vala.FloatingType vfty)
        {
            var rank = float_type_get_rank(vfty);
            switch (rank) {
                default:
                    crash(@"type $vfty has illegal rank $rank (1 for IEEE float32, 2 for IEEE float64)");
                case 1: return type_ctx.ieee_f32;
                case 2: return type_ctx.ieee_f64;
            }
        }
        public ArrayType map_fixed_array_type(Vala.ArrayType vaty)
        {
            if (unlikely(!vaty.fixed_length))
                crash(@"mapping unfixed array type $vaty requries map_unfixed_array_type()");
            bool is_signed;
            var itype = map_get_type(vaty.element_type, out is_signed);
            return type_ctx.get_array_type(itype, eval_expr_int(vaty.length));
        }
        public PointerType map_unfixed_array_type(Vala.ArrayType vaty, out Vala.Expression length_expr)
        {
            if (!unlikely(vaty.fixed_length))
                crash(@"mapping fixed array type $vaty requries map_unfixed_array_type()");
            length_expr = vaty.length;
            bool is_signed;
            var itype = map_get_type(vaty.element_type, out is_signed);
            return type_ctx.get_ptr_type(itype);
        }
        public PointerType map_ptr_type(Vala.PointerType vpty)
        {
            bool is_signed;
            var itarget = map_get_type(vpty, out is_signed);
            return type_ctx.get_ptr_type(itarget);
        }
        private size_t eval_expr_int(Vala.Expression expr) {
            assert_not_reached();
        }
        public Musys.Type map_get_type(Vala.DataType vtype, out bool is_signed)
        {
            is_signed = false;
            if (vtype is Vala.IntegerType) {
                is_signed = true;
                return map_int_type(static_cast<Vala.IntegerType>(vtype)).int_ty;
            }
            if (vtype is Vala.FloatingType) {
                is_signed = true;
                return map_float_type(static_cast<Vala.FloatingType>(vtype));
            }
            if (vtype is Vala.NullType)
                return type_ctx.get_ptr_type(type_ctx.void_type);
            if (vtype is Vala.PointerType)
                return map_ptr_type(static_cast<Vala.PointerType>(vtype));
            if (vtype is Vala.ArrayType) {
                unowned Vala.ArrayType varrty = static_cast<Vala.ArrayType>(vtype);
                Vala.Expression length_expr = null;
                return varrty.fixed_length?
                       (Type)map_fixed_array_type(varrty):
                       (Type)map_unfixed_array_type(varrty, out length_expr);
            }
            crash(@"Musys does not support type $vtype\n(at $(vtype.source_reference))");
        }

        public TypeMapper.as_64bit(Generator generator, bool long_follows_int = false) {
            TypeContext tctx = generator.module.type_ctx;
            this.type_ctx = tctx;
            if (tctx.machine_word_size != 8)
                crash("64-bit target requires machine word size equal to 8");
            this._vintty_rank_map[0] = tctx.bool_type;

            /* IntType ranks: [1 int8]; [2 char]; [3 uchar] */
            var i8ty = tctx.get_int_type(8);
            this._vintty_rank_map[1] = i8ty;
            this._vintty_rank_map[2] = i8ty; this._vintty_rank_map[3] = i8ty;
            this._vintty_rank_signed[1] = true; this._vintty_rank_signed[2] = true;

            /* IntType ranks: [4 int16; short]; [5 uint16; ushort] */
            var i16ty = tctx.get_int_type(16);
            this._vintty_rank_map[4] = i16ty; this._vintty_rank_map[5] = i16ty;
            this._vintty_rank_signed[5] = true;

            /* IntType ranks: [6 int32; int]; [7 uint32; uint] */
            var i32ty = tctx.get_int_type(32);
            this._vintty_rank_map[6] = i32ty; this._vintty_rank_map[7] = i32ty;
            this._vintty_rank_signed[6] = true;

            /* IntType Ranks: [10 int64]; [11 uint64] */
            var i64ty = tctx.get_int_type(64);
            this._vintty_rank_map[10] = i64ty; this._vintty_rank_map[11] = i64ty;
            this._vintty_rank_signed[10] = true;

            /* IntType Ranks: [8 long]; [9 ulong] */
            unowned IntType longty = long_follows_int? i32ty: i64ty;
            this._vintty_rank_map[8] = longty; this._vintty_rank_map[9] = longty;
            this._vintty_rank_signed[8] = true;
        }
        public TypeMapper.as_32bit(Generator generator)
        {
            TypeContext tctx = generator.module.type_ctx;
            this.type_ctx = tctx;
            if (tctx.machine_word_size != 4)
                crash("32-bit target requires machine word size qeual to 4");
            this._vintty_rank_map[0] = tctx.bool_type;

            /* IntType ranks: [4 int16; short]; [5 uint16; ushort] */
            var i16ty = tctx.get_int_type(16);
            this._vintty_rank_map[4] = i16ty; this._vintty_rank_map[5] = i16ty;
            this._vintty_rank_signed[5] = true;

            /* IntType ranks: [6 int32; int]; [7 uint32; uint] */
            var i32ty = tctx.get_int_type(32);
            this._vintty_rank_map[6] = i32ty; this._vintty_rank_map[7] = i32ty;
            this._vintty_rank_signed[6] = true;

            /* IntType Ranks: [10 int64]; [11 uint64] */
            var i64ty = tctx.get_int_type(64);
            this._vintty_rank_map[10] = i64ty; this._vintty_rank_map[11] = i64ty;
            this._vintty_rank_signed[10] = true;

            /* IntType Ranks: [8 long]; [9 ulong] */
            unowned IntType longty = i32ty;
            this._vintty_rank_map[8] = longty; this._vintty_rank_map[9] = longty;
            this._vintty_rank_signed[8] = true;
        }
        public TypeMapper() {}
        public TypeMapper.from(Generator generator, IntType []ity_ranks) {
            this.parent   = generator;
            this.type_ctx = parent.module.type_ctx;
            if (ity_ranks.length != _vintty_rank_map.length) {
                crash_fmt(SourceLocation.current(),
                          "Requires int type rank array size equal to %d, but got %d",
                          _vintty_rank_map.length, ity_ranks.length);
            }
            for (int i = 0; i < ity_ranks.length; i++)
                _vintty_rank_map[i] = ity_ranks[i];
        }

        public struct IntTypeInfo {
            unowned IntType int_ty;
            bool         is_signed;
        }
    }
}