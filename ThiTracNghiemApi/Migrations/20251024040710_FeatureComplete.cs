using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ThiTracNghiemApi.Migrations
{
    /// <inheritdoc />
    public partial class FeatureComplete : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "NgayThi",
                table: "KetQuaThis",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<double>(
                name: "Diem",
                table: "KetQuaThis",
                type: "float",
                nullable: false,
                oldClrType: typeof(float),
                oldType: "real");

            migrationBuilder.AddColumn<DateTime>(
                name: "NgayNopBai",
                table: "KetQuaThis",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SoCauDung",
                table: "KetQuaThis",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "TrangThai",
                table: "KetQuaThis",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "DangLam");

            migrationBuilder.AddColumn<bool>(
                name: "DungHaySai",
                table: "ChiTietKetQuaThis",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AvatarUrl",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "AspNetUsers",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<string>(
                name: "GioiTinh",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "NgaySinh",
                table: "AspNetUsers",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SoDienThoai",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "TrangThaiKhoa",
                table: "AspNetUsers",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "NgayNopBai",
                table: "KetQuaThis");

            migrationBuilder.DropColumn(
                name: "SoCauDung",
                table: "KetQuaThis");

            migrationBuilder.DropColumn(
                name: "TrangThai",
                table: "KetQuaThis");

            migrationBuilder.DropColumn(
                name: "DungHaySai",
                table: "ChiTietKetQuaThis");

            migrationBuilder.DropColumn(
                name: "AvatarUrl",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "GioiTinh",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "NgaySinh",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "SoDienThoai",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "TrangThaiKhoa",
                table: "AspNetUsers");

            migrationBuilder.AlterColumn<DateTime>(
                name: "NgayThi",
                table: "KetQuaThis",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETUTCDATE()");

            migrationBuilder.AlterColumn<float>(
                name: "Diem",
                table: "KetQuaThis",
                type: "real",
                nullable: false,
                oldClrType: typeof(double),
                oldType: "float");
        }
    }
}
